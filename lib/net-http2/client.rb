require 'socket'
require 'openssl'
require 'uri'
require 'http/2'

module NetHttp2

  DRAFT = 'h2'

  class Client
    attr_reader :uri

    def initialize(url, options={})
      @uri         = URI.parse(url)
      @ssl_context = add_npn_to_context(options[:ssl_context] || OpenSSL::SSL::SSLContext.new)

      @is_ssl = (@uri.scheme == 'https')

      @pipe_r, @pipe_w = Socket.pair(:UNIX, :STREAM, 0)
      @socket_thread   = nil
      @mutex           = Mutex.new
    end

    def get(path, headers={}, options={})
      request = NetHttp2::Request::Get.new(@uri, path, headers, options)
      call_with request
    end

    def post(path, body, headers={}, options={})
      request = NetHttp2::Request::Post.new(@uri, path, body, headers, options)
      call_with request
    end

    def put(path, body, headers={}, options={})
      request = NetHttp2::Request::Put.new(@uri, path, body, headers, options)
      call_with request
    end

    def delete(path, headers={}, options={})
      request = NetHttp2::Request::Delete.new(@uri, path, headers, options)
      call_with request
    end

    def async_get(path, headers={}, options={}, &block)
      request = NetHttp2::Request::Get.new(@uri, path, headers, options)
      async_call_with request, &block
    end

    def async_post(path, body, headers={}, options={}, &block)
      request = NetHttp2::Request::Post.new(@uri, path, body, headers, options)
      async_call_with request, &block
    end

    def async_put(path, body, headers={}, options={}, &block)
      request = NetHttp2::Request::Put.new(@uri, path, body, headers, options)
      async_call_with request, &block
    end

    def async_delete(path, headers={}, options={}, &block)
      request = NetHttp2::Request::Delete.new(@uri, path, headers, options)
      async_call_with request, &block
    end

    def ssl?
      @is_ssl
    end

    def close
      exit_thread(@socket_thread)

      @h2            = nil
      @pipe_r        = nil
      @pipe_w        = nil
      @socket_thread = nil
    end

    private

    def call_with(request)
      ensure_open
      new_stream.call_with request
    end

    def async_call_with(request, &block)
      ensure_open
      new_stream.async_call_with request, &block
    end

    def new_stream
      NetHttp2::Stream.new(uri: @uri, h2_stream: h2.new_stream)
    end

    def ensure_open
      return if @socket_thread

      socket = new_socket

      @socket_thread = Thread.new do

        begin
          thread_loop(socket)
        ensure
          socket.close unless socket.closed?
          @socket_thread = nil
        end
      end
    end

    def thread_loop(socket)

      send_before_receiving(socket)

      loop do

        next if read_if_pending(socket)

        ready = IO.select([socket, @pipe_r])

        if ready[0].include?(socket)
          data_received = socket.readpartial(1024)
          h2 << data_received
        end

        if ready[0].include?(@pipe_r)
          data_to_send = @pipe_r.read_nonblock(1024)
          socket.write(data_to_send)
        end
      end
    end

    def new_socket
      tcp = TCPSocket.new(@uri.host, @uri.port)

      if ssl?
        socket            = OpenSSL::SSL::SSLSocket.new(tcp, @ssl_context)
        socket.sync_close = true
        socket.hostname   = @uri.hostname

        socket.connect
        raise "Failed to negotiate #{DRAFT} via NPN" if socket.npn_protocol != DRAFT

        socket
      else
        tcp
      end
    end

    def send_before_receiving(socket)
      data_to_send = @pipe_r.read_nonblock(1024)
      socket.write(data_to_send)
    rescue IO::WaitReadable
      IO.select([@pipe_r])
      retry
    end

    def read_if_pending(socket)
      if ssl?
        available = socket.pending

        if available > 0
          data_received = socket.sysread(available)
          h2 << data_received

          true
        end
      end
    end

    def h2
      @h2 ||= HTTP2::Client.new.tap do |h2|
        h2.on(:frame) do |bytes|
          @mutex.synchronize do
            @pipe_w.write(bytes)
            @pipe_w.flush
          end
        end
      end
    end

    def add_npn_to_context(ctx)
      ctx.npn_protocols = [DRAFT]
      ctx.npn_select_cb = lambda do |protocols|
        DRAFT if protocols.include?(DRAFT)
      end
      ctx
    end

    def exit_thread(thread)
      return unless thread && thread.alive?
      thread.exit
      thread.join
    end
  end
end

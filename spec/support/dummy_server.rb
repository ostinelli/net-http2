# frozen-string-literal: false
module NetHttp2

  module Dummy

    class Request
      attr_accessor :body
      attr_reader :headers

      def initialize
        @body = ''
      end

      def import_headers(h)
        @headers = Hash[*h.flatten]
      end
    end

    class Server
      DRAFT = 'h2'

      attr_accessor :on_req

      def initialize(options={})
        @is_ssl        = options[:ssl]
        @port          = options[:port]
        @listen_thread = nil
        @threads       = []
      end

      def listen
        @server = new_server

        @listen_thread = Thread.new do
          loop do
            Thread.start(@server.accept) do |socket|
              @threads << Thread.current
              handle(socket)
            end.tap { |t| t.abort_on_exception = true }
          end
        end.tap { |t| t.abort_on_exception = true }
      end

      def stop
        exit_thread(@listen_thread)
        @threads.each { |t| exit_thread(t) }

        @server.close

        @server        = nil
        @ssl_context   = nil
        @listen_thread = nil
        @threads       = []
      end

      private

      def cert_file_path
        File.expand_path('../priv/server.crt', __FILE__)
      end

      def key_file_path
        File.expand_path('../priv/server.key', __FILE__)
      end

      def handle(socket)
        conn = HTTP2::Server.new

        conn.on(:frame) { |bytes| socket.write(bytes) }
        conn.on(:stream) do |stream|
          req = NetHttp2::Dummy::Request.new

          stream.on(:headers) { |h| req.import_headers(h) }
          stream.on(:data) { |d| req.body << d }
          stream.on(:half_close) do

            # callbacks
            res = if on_req
              on_req.call(req, stream, socket)
            else
              NetHttp2::Response.new(
                headers: { ":status" => "200" },
                body:    "response body"
              )
            end

            if res.is_a?(Response)
              stream.headers({
                ':status'        => res.headers[":status"],
                'content-length' => res.body.bytesize.to_s,
                'content-type'   => 'text/plain',
              }, end_stream: false)

              stream.data(res.body, end_stream: true)
            end
          end
        end

        while socket && !socket.closed? && !socket.eof?
          data = socket.read_nonblock(1024)
          conn << data
        end

        socket.close unless socket.closed?
      end

      def new_server
        s = TCPServer.new(@port)
        @is_ssl ? OpenSSL::SSL::SSLServer.new(s, ssl_context) : s
      end

      def ssl_context
        @ssl_context ||= begin
          ctx               = OpenSSL::SSL::SSLContext.new
          ctx.cert          = OpenSSL::X509::Certificate.new(File.open(cert_file_path))
          ctx.key           = OpenSSL::PKey::RSA.new(File.open(key_file_path))
          ctx.npn_protocols = [DRAFT]
          ctx
        end
      end

      def exit_thread(thread)
        return unless thread
        thread.exit
        thread.join
      end
    end
  end
end

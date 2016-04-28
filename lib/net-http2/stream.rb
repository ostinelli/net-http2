module NetHttp2

  class Stream

    def initialize(options={})
      @h2_stream = options[:h2_stream]
      @uri       = options[:uri]
      @headers   = {}
      @data      = ''
      @completed = false
      @block     = nil

      @h2_stream.on(:headers) do |hs|
        hs.each { |k, v| @headers[k] = v }
      end

      @h2_stream.on(:data) { |d| @data << d }
      @h2_stream.on(:close) { mark_as_completed_and_async_respond }
    end

    def call_with(request)
      send_data_of request
      sync_respond(request.timeout)
    end

    def async_call_with(request, &block)
      @block = block
      send_data_of request
    end

    private

    def send_data_of(request)
      headers = request.headers
      body    = request.body

      if body
        @h2_stream.headers(headers, end_stream: false)
        @h2_stream.data(body, end_stream: true)
      else
        @h2_stream.headers(headers, end_stream: true)
      end
    end

    def mark_as_completed_and_async_respond
      @completed = true
      @block.call(response) if @block
    end

    def sync_respond(timeout)
      wait(timeout)
      response if @completed
    end

    def response
      NetHttp2::Response.new(
        headers: @headers,
        body:    @data
      )
    end

    def wait(timeout)
      cutoff_time = Time.now + timeout

      while !@completed && Time.now < cutoff_time
        sleep 0.1
      end
    end
  end
end

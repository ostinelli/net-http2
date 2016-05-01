module NetHttp2

  class Request

    DEFAULT_TIMEOUT = 60

    attr_reader :method, :uri, :path, :body, :timeout

    def initialize(method, uri, path, options={})
      @method  = method
      @uri     = uri
      @path    = path
      @body    = options[:body]
      @headers = options[:headers] || {}
      @timeout = options[:timeout] || DEFAULT_TIMEOUT

      @events = {}
    end

    def headers
      @headers.merge!({
        ':scheme' => @uri.scheme,
        ':method' => @method.to_s.upcase,
        ':path'   => @path,
      })

      @headers.merge!('host' => @uri.host) unless @headers['host']

      if @body
        @headers.merge!('content-length' => @body.bytesize.to_s)
      else
        @headers.delete('content-length')
      end

      @headers
    end

    def on(event, &block)
      raise ArgumentError, 'on event must provide a block' unless block_given?

      @events[event] ||= []
      @events[event] << block
    end

    def emit(event, arg)
      return unless @events[event]
      @events[event].each { |b| b.call(arg) }
    end
  end
end

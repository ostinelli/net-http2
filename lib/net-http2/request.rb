module NetHttp2

  class Request

    DEFAULT_TIMEOUT = 60

    attr_reader :method, :uri, :path, :body, :timeout

    def initialize(method, uri, path, options)
      @method  = method
      @uri     = uri
      @path    = path
      @body    = options[:body]
      @headers = options[:headers] || {}
      @timeout = options[:timeout] || DEFAULT_TIMEOUT
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
  end
end

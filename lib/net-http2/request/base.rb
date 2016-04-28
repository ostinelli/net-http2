module NetHttp2

  module Request

    DEFAULT_TIMEOUT = 60

    class Base
      attr_reader :uri, :path, :body, :timeout

      def initialize(method, uri, path, body, headers, options={})
        @method  = method
        @uri     = uri
        @path    = path
        @body    = body
        @headers = headers
        @timeout = options[:timeout] || DEFAULT_TIMEOUT
      end

      def headers
        @headers.merge!({
          ':scheme'        => @uri.scheme,
          ':method'        => @method,
          ':path'          => @path,
        })

        @headers.merge!('host' => @uri.host) unless @headers['host']
        @headers.merge!('content-length' => @body.bytesize.to_s) if @body

        @headers
      end
    end
  end
end

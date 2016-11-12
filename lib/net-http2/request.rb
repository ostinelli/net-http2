require 'cgi'

module NetHttp2

  class Request

    DEFAULT_TIMEOUT = 60

    attr_reader :method, :uri, :path, :params, :body, :timeout

    def initialize(method, uri, path, options={})
      @method  = method
      @uri     = uri
      @path    = path
      @params  = options[:params] || {}
      @body    = options[:body]
      @headers = options[:headers] || {}
      @timeout = options[:timeout] || DEFAULT_TIMEOUT

      @events = {}
    end

    def headers
      @headers.merge!({
        ':scheme' => @uri.scheme,
        ':method' => @method.to_s.upcase,
        ':path'   => full_path,
      })

      @headers.merge!(':authority' => "#{@uri.host}:#{@uri.port}") unless @headers[':authority']

      if @body
        @headers.merge!('content-length' => @body.bytesize.to_s)
      else
        @headers.delete('content-length')
      end

      @headers
    end

    def full_path
      path = @path
      path += "?#{to_query(@params)}" unless @params.empty?
      path
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

    private

    def to_param(element)
      if element.is_a?(TrueClass) || element.is_a?(FalseClass) || element.is_a?(NilClass)
        element
      elsif element.is_a?(Array)
        element.collect(&:to_param).join '/'
      else
        element.to_s.strip
      end
    end

    def to_query(element, namespace_or_key = nil)
      if element.is_a?(Hash)
        element.collect do |key, value|
          unless (value.is_a?(Hash) || value.is_a?(Array)) && value.empty?
            to_query(value, namespace_or_key ? "#{namespace_or_key}[#{key}]" : key)
          end
        end.compact.sort! * '&'
      elsif element.is_a?(Array)
        prefix = "#{namespace_or_key}[]"

        if element.empty?
          to_query(nil, prefix)
        else
          element.collect { |value| to_query(value, prefix) }.join '&'
        end
      else
        "#{CGI.escape(to_param(namespace_or_key))}=#{CGI.escape(to_param(element).to_s)}"
      end
    end
  end
end

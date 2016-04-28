module NetHttp2

  module Request

    class Get < Base

      def initialize(uri, path, headers, options)
        super('GET', uri, path, nil, headers, options)
      end
    end
  end
end

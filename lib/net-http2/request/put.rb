module NetHttp2

  module Request

    class Put < Base

      def initialize(uri, path, body, headers, options)
        super('PUT', uri, path, body, headers, options)
      end
    end
  end
end

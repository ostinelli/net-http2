module NetHttp2

  module Request

    class Post < Base

      def initialize(uri, path, body, headers, options)
        super('POST', uri, path, body, headers, options)
      end
    end
  end
end

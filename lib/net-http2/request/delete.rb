module NetHttp2

  module Request

    class Delete < Base

      def initialize(uri, path, headers, options)
        super('DELETE', uri, path, nil, headers, options)
      end
    end
  end
end

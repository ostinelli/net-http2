module NetHttp2

  module ApiHelpers

    def apn_file_path
      File.expand_path('../priv/apn.pem', __FILE__)
    end

    def cert_file_path
      File.expand_path('../priv/server.crt', __FILE__)
    end

    def key_file_path
      File.expand_path('../priv/server.key', __FILE__)
    end
  end
end

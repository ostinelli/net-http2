require 'net-http2/version'

module NetHttp2
  raise "Cannot require NetHttp2, unsupported engine '#{RUBY_ENGINE}'" unless RUBY_ENGINE == "ruby"
end

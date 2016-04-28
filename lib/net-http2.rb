require 'net-http2/request/base'
require 'net-http2/request/get'
require 'net-http2/request/post'
require 'net-http2/version'

module NetHttp2
  raise "Cannot require NetHttp2, unsupported engine '#{RUBY_ENGINE}'" unless RUBY_ENGINE == "ruby"
end

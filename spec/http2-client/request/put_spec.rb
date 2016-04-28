require 'spec_helper'

describe NetHttp2::Request::Put do

  it_behaves_like "a NetHttp2 Request with a body", method: 'PUT'
end

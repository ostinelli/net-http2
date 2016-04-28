require 'spec_helper'

describe NetHttp2::Request::Get do

  it_behaves_like "a NetHttp2 Request with no body", method: 'GET'
end

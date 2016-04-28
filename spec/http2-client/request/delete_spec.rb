require 'spec_helper'

describe NetHttp2::Request::Delete do

  it_behaves_like "a NetHttp2 Request with no body", method: 'DELETE'
end

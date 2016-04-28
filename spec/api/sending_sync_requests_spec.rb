require 'spec_helper'

describe "Sending sync requests" do
  let(:port) { 9516 }
  let(:server) { NetHttp2::Dummy::Server.new(port: port) }
  let(:client) { NetHttp2::Client.new(uri: "http://localhost:#{port}") }

  before { server.listen }
  after do
    client.close
    server.stop
  end

  it "sends GET requests with the correct parameters" do
    request       = nil
    server.on_req = Proc.new do |req|
      request = req

      res                    = NetHttp2::Dummy::Response.new
      res.headers[":status"] = "200"
      res.body               = "response body"
      res
    end

    response = client.get('/path', { 'x-custom-header' => 'custom' })

    expect(response).to be_a NetHttp2::Response
    expect(response.body).to eq "response body"

    expect(request).not_to be_nil
    expect(request.headers[":scheme"]).to eq "http"
    expect(request.headers[":method"]).to eq "GET"
    expect(request.headers[":path"]).to eq "/path"
    expect(request.headers["host"]).to eq "localhost"
    expect(request.headers["x-custom-header"]).to eq "custom"
  end

  it "sends POST requests with the correct parameters" do
    request       = nil
    server.on_req = Proc.new do |req|
      request = req

      res                    = NetHttp2::Dummy::Response.new
      res.headers[":status"] = "200"
      res.body               = "response body"
      res
    end

    response = client.post('/path', "body", { 'x-custom-header' => 'custom' })

    expect(response).to be_a NetHttp2::Response
    expect(response.body).to eq "response body"

    expect(request).not_to be_nil
    expect(request.headers[":scheme"]).to eq "http"
    expect(request.headers[":method"]).to eq "POST"
    expect(request.headers[":path"]).to eq "/path"
    expect(request.headers["host"]).to eq "localhost"
    expect(request.headers["x-custom-header"]).to eq "custom"

    expect(request.body).to eq "body"
  end

  it "sends PUT requests with the correct parameters" do
    request       = nil
    server.on_req = Proc.new do |req|
      request = req

      res                    = NetHttp2::Dummy::Response.new
      res.headers[":status"] = "200"
      res.body               = "response body"
      res
    end

    response = client.put('/path', "body", { 'x-custom-header' => 'custom' })

    expect(response).to be_a NetHttp2::Response
    expect(response.body).to eq "response body"

    expect(request).not_to be_nil
    expect(request.headers[":scheme"]).to eq "http"
    expect(request.headers[":method"]).to eq "PUT"
    expect(request.headers[":path"]).to eq "/path"
    expect(request.headers["host"]).to eq "localhost"
    expect(request.headers["x-custom-header"]).to eq "custom"

    expect(request.body).to eq "body"
  end

  it "sends DELETE requests with the correct parameters" do
    request       = nil
    server.on_req = Proc.new do |req|
      request = req

      res                    = NetHttp2::Dummy::Response.new
      res.headers[":status"] = "200"
      res.body               = "response body"
      res
    end

    response = client.delete('/path', { 'x-custom-header' => 'custom' })

    expect(response).to be_a NetHttp2::Response
    expect(response.body).to eq "response body"

    expect(request).not_to be_nil
    expect(request.headers[":scheme"]).to eq "http"
    expect(request.headers[":method"]).to eq "DELETE"
    expect(request.headers[":path"]).to eq "/path"
    expect(request.headers["host"]).to eq "localhost"
    expect(request.headers["x-custom-header"]).to eq "custom"
  end

  it "sends multiple GET requests sequentially" do
    requests      = []
    server.on_req = Proc.new do |req|
      requests << req

      res                    = NetHttp2::Dummy::Response.new
      res.headers[":status"] = "200"
      res.body               = "response for #{req.headers[':path']}"
      res
    end

    response_1 = client.get('/path1')
    response_2 = client.get('/path2')

    expect(response_1).to be_a NetHttp2::Response
    expect(response_1.body).to eq "response for /path1"
    expect(response_2).to be_a NetHttp2::Response
    expect(response_2.body).to eq "response for /path2"

    request_1, request_2 = requests
    expect(request_1).not_to be_nil
    expect(request_2).not_to be_nil
  end

  it "sends multiple GET requests concurrently" do
    requests      = []
    server.on_req = Proc.new do |req|
      requests << req

      res                    = NetHttp2::Dummy::Response.new
      res.headers[":status"] = "200"
      res.body               = "response for #{req.headers[':path']}"
      res
    end

    response_1 = nil
    thread     = Thread.new { response_1 = client.get('/path1') }
    response_2 = client.get('/path2')

    thread.join

    expect(response_1).to be_a NetHttp2::Response
    expect(response_1.body).to eq "response for /path1"
    expect(response_2).to be_a NetHttp2::Response
    expect(response_2.body).to eq "response for /path2"

    request_1, request_2 = requests
    expect(request_1).not_to be_nil
    expect(request_2).not_to be_nil
  end
end

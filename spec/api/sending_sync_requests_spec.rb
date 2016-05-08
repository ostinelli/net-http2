require 'spec_helper'

describe "Sending sync requests" do
  let(:port) { 9516 }
  let(:server) { NetHttp2::Dummy::Server.new(port: port) }
  let(:client) { NetHttp2::Client.new("http://localhost:#{port}") }

  before { server.listen }

  after do
    client.close
    server.stop
  end

  it "sends a request without a body" do
    request       = nil
    server.on_req = Proc.new do |req|
      request = req

      NetHttp2::Response.new(
        headers: { ":status" => "200" },
        body:    "response body"
      )
    end

    response = client.call(:get, '/path',
      headers: { 'x-custom-header' => 'custom' }
    )

    expect(response).to be_a NetHttp2::Response
    expect(response.body).to eq "response body"

    expect(request).not_to be_nil
    expect(request.headers[":scheme"]).to eq "http"
    expect(request.headers[":method"]).to eq "GET"
    expect(request.headers[":path"]).to eq "/path"
    expect(request.headers["host"]).to eq "localhost"
    expect(request.headers["x-custom-header"]).to eq "custom"
  end

  it "sends a request with a body" do
    request       = nil
    server.on_req = Proc.new do |req|
      request = req

      NetHttp2::Response.new(
        headers: { ":status" => "200" },
        body:    "response body"
      )
    end

    response = client.call(:post, '/path',
      body:    "body",
      headers: { 'x-custom-header' => 'custom' }
    )

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

  it "sends multiple GET requests sequentially" do
    requests      = []
    server.on_req = Proc.new do |req|
      requests << req

      NetHttp2::Response.new(
        headers: { ":status" => "200" },
        body:    "response for #{req.headers[':path']}"
      )
    end

    response_1 = client.call(:get, '/path1')
    response_2 = client.call(:get, '/path2')

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

      NetHttp2::Response.new(
        headers: { ":status" => "200" },
        body:    "response for #{req.headers[':path']}"
      )
    end

    response_1 = nil
    thread     = Thread.new { response_1 = client.call(:get, '/path1') }
    response_2 = client.call(:get, '/path2')

    thread.join

    expect(response_1).to be_a NetHttp2::Response
    expect(response_1.body).to eq "response for /path1"
    expect(response_2).to be_a NetHttp2::Response
    expect(response_2.body).to eq "response for /path2"

    request_1, request_2 = requests
    expect(request_1).not_to be_nil
    expect(request_2).not_to be_nil
  end

  it "sends GET requests and receives big bodies" do
    big_body = "a" * 100_000

    server.on_req = Proc.new do |_req|
      NetHttp2::Response.new(
        headers: { ":status" => "200" },
        body:    big_body.dup
      )
    end

    response = client.call(:get, '/path', timeout: 5)

    expect(response).to be_a NetHttp2::Response
    expect(response.body).to eq big_body
  end

  it "sends POST requests with big bodies" do
    received_body = nil
    server.on_req = Proc.new do |req|
      received_body = req.body

      NetHttp2::Response.new(
        headers: { ":status" => "200" },
        body:    "response ok"
      )
    end

    big_body = "a" * 100_000
    response = client.call(:post, '/path', body: big_body.dup, timeout: 5)

    expect(response).to be_a NetHttp2::Response
    expect(received_body).to eq big_body
  end
end

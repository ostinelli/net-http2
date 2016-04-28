require 'spec_helper'

describe "Sending async requests" do
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

    response = nil
    client.async_get('/path', { 'x-custom-header' => 'custom' }) { |res| response = res }

    wait_for { !response.nil? }

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

    response = nil
    client.async_post('/path', "body", { 'x-custom-header' => 'custom' }) { |res| response = res }

    wait_for { !response.nil? }

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

    response = nil
    client.async_put('/path', "body", { 'x-custom-header' => 'custom' }) { |res| response = res }

    wait_for { !response.nil? }

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

    response = nil
    client.async_delete('/path', { 'x-custom-header' => 'custom' }) { |res| response = res }

    wait_for { !response.nil? }

    expect(response).to be_a NetHttp2::Response
    expect(response.body).to eq "response body"

    expect(request).not_to be_nil
    expect(request.headers[":scheme"]).to eq "http"
    expect(request.headers[":method"]).to eq "DELETE"
    expect(request.headers[":path"]).to eq "/path"
    expect(request.headers["host"]).to eq "localhost"
    expect(request.headers["x-custom-header"]).to eq "custom"
  end
end

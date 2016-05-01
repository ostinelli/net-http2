require 'spec_helper'

describe "Sending async requests" do
  let(:port) { 9516 }
  let(:server) { NetHttp2::Dummy::Server.new(port: port) }
  let(:client) { NetHttp2::Client.new("http://localhost:#{port}") }

  before { server.listen }

  after do
    client.close
    server.stop
  end

  it "sends async a request without a body" do
    incoming_request = nil
    reply_done       = false
    server.on_req    = Proc.new do |req, stream|
      incoming_request = req

      body_chunk_1 = "response body"
      body_chunk_2 = " and another chunk"

      stream.headers({
        ':status'        => "200",
        'content-length' => (body_chunk_1 + body_chunk_2).bytesize.to_s
      }, end_stream: false)

      stream.data(body_chunk_1, end_stream: false)
      stream.data(body_chunk_2, end_stream: true)

      reply_done = true
    end

    request = client.prepare_request(:get, '/path', headers: { 'x-custom-header' => 'custom' })

    headers   = nil
    body      = ''
    completed = false
    request.on(:headers) { |hs| headers = hs }
    request.on(:body_chunk) { |chunk| body << chunk }
    request.on(:close) { completed = true }

    expect(request).to be_a NetHttp2::Request

    client.call_async(request)

    wait_for { reply_done }

    expect(headers).to_not be_nil
    expect(body).to_not eq ''

    expect(headers[':status']).to eq "200"
    expect(headers['content-length']).to eq "31"
    expect(body).to eq "response body and another chunk"
    expect(completed).to eq true

    expect(incoming_request).not_to be_nil
    expect(incoming_request.headers[":scheme"]).to eq "http"
    expect(incoming_request.headers[":method"]).to eq "GET"
    expect(incoming_request.headers[":path"]).to eq "/path"
    expect(incoming_request.headers["host"]).to eq "localhost"
    expect(incoming_request.headers["x-custom-header"]).to eq "custom"
  end

  it "sends async a request with a body" do
    incoming_request = nil
    reply_done       = false
    server.on_req    = Proc.new do |req, stream|
      incoming_request = req

      body_chunk_1 = "response body"
      body_chunk_2 = " and another chunk"

      stream.headers({
        ':status'        => "200",
        'content-length' => (body_chunk_1 + body_chunk_2).bytesize.to_s
      }, end_stream: false)

      stream.data(body_chunk_1, end_stream: false)
      stream.data(body_chunk_2, end_stream: true)

      reply_done = true
    end

    request = client.prepare_request(:get, '/path',
      headers: { 'x-custom-header' => 'custom' },
      body:    "request body"
    )

    headers   = nil
    body      = ''
    completed = false
    request.on(:headers) { |hs| headers = hs }
    request.on(:body_chunk) { |chunk| body << chunk }
    request.on(:close) { completed = true }

    expect(request).to be_a NetHttp2::Request

    client.call_async(request)

    wait_for { reply_done }

    expect(headers).to_not be_nil
    expect(headers[':status']).to eq "200"
    expect(headers['content-length']).to eq "31"

    expect(body).to eq "response body and another chunk"
    expect(completed).to eq true

    expect(incoming_request).not_to be_nil
    expect(incoming_request.headers[":scheme"]).to eq "http"
    expect(incoming_request.headers[":method"]).to eq "GET"
    expect(incoming_request.headers[":path"]).to eq "/path"
    expect(incoming_request.headers["host"]).to eq "localhost"
    expect(incoming_request.headers["x-custom-header"]).to eq "custom"
    expect(incoming_request.body).to eq "request body"
  end

  it "sends multiple requests sequentially" do
    replies_done  = 0
    server.on_req = Proc.new do |req, stream|
      body_chunk_1 = "response body for #{req.headers[':path']}"
      body_chunk_2 = " and another chunk"

      stream.headers({
        ':status'        => "200",
        'content-length' => (body_chunk_1 + body_chunk_2).bytesize.to_s
      }, end_stream: false)

      stream.data(body_chunk_1, end_stream: false)
      stream.data(body_chunk_2, end_stream: true)

      replies_done += 1
    end

    request_1 = client.prepare_request(:get, '/path1')
    expect(request_1).to be_a NetHttp2::Request

    headers_1   = nil
    body_1      = ''
    completed_1 = false
    request_1.on(:headers) { |hs| headers_1 = hs }
    request_1.on(:body_chunk) { |chunk| body_1 << chunk }
    request_1.on(:close) { completed_1 = true }

    request_2 = client.prepare_request(:get, '/path2')
    expect(request_2).to be_a NetHttp2::Request

    headers_2   = nil
    body_2      = ''
    completed_2 = false
    request_2.on(:headers) { |hs| headers_2 = hs }
    request_2.on(:body_chunk) { |chunk| body_2 << chunk }
    request_2.on(:close) { completed_2 = true }

    client.call_async(request_1)
    client.call_async(request_2)

    wait_for { replies_done == 2 }

    expect(headers_1).to_not be_nil
    expect(headers_1[':status']).to eq "200"
    expect(headers_1['content-length']).to eq "42"

    expect(headers_2).to_not be_nil
    expect(headers_2[':status']).to eq "200"
    expect(headers_2['content-length']).to eq "42"

    expect(body_1).to eq "response body for /path1 and another chunk"
    expect(body_2).to eq "response body for /path2 and another chunk"

    expect(completed_1).to eq true
    expect(completed_2).to eq true
  end

  it "sends multiple requests concurrently" do
    replies_done  = 0
    server.on_req = Proc.new do |req, stream|
      body_chunk_1 = "response body for #{req.headers[':path']}"
      body_chunk_2 = " and another chunk"

      stream.headers({
        ':status'        => "200",
        'content-length' => (body_chunk_1 + body_chunk_2).bytesize.to_s
      }, end_stream: false)

      stream.data(body_chunk_1, end_stream: false)
      stream.data(body_chunk_2, end_stream: true)

      replies_done += 1
    end

    request_1 = client.prepare_request(:get, '/path1')
    expect(request_1).to be_a NetHttp2::Request

    headers_1   = nil
    body_1      = ''
    completed_1 = false
    request_1.on(:headers) { |hs| headers_1 = hs }
    request_1.on(:body_chunk) { |chunk| body_1 << chunk }
    request_1.on(:close) { completed_1 = true }

    request_2 = client.prepare_request(:get, '/path2')
    expect(request_2).to be_a NetHttp2::Request

    headers_2   = nil
    body_2      = ''
    completed_2 = false
    request_2.on(:headers) { |hs| headers_2 = hs }
    request_2.on(:body_chunk) { |chunk| body_2 << chunk }
    request_2.on(:close) { completed_2 = true }

    client.call_async(request_1)
    thread     = Thread.new { client.call_async(request_2) }
    thread.join

    wait_for { replies_done == 2 }

    expect(headers_1).to_not be_nil
    expect(headers_1[':status']).to eq "200"
    expect(headers_1['content-length']).to eq "42"

    expect(headers_2).to_not be_nil
    expect(headers_2[':status']).to eq "200"
    expect(headers_2['content-length']).to eq "42"

    expect(body_1).to eq "response body for /path1 and another chunk"
    expect(body_2).to eq "response body for /path2 and another chunk"

    expect(completed_1).to eq true
    expect(completed_2).to eq true
  end
end

require 'spec_helper'

describe "Timeouts with async requests" do
  let(:port) { 9516 }
  let(:server) { NetHttp2::Dummy::Server.new(port: port) }
  let(:client) { NetHttp2::Client.new("http://localhost:#{port}") }

  before do
    server.listen
    server.on_req = Proc.new { |_req| sleep 3 }
  end

  after do
    client.close
    server.stop
  end

  it "returns nil when no response is received within the specified timeout" do
    response = true
    client.async_get('/path', { 'x-custom-header' => 'custom' }, timeout: 1) { |res| response = res }

    wait_for { response.nil? }
    expect(response).to be_nil
  end

  it "returns nil when no sequential responses are received within the specified timeout" do
    responses = []
    client.async_get('/path', { 'x-custom-header' => 'custom' }, timeout: 1) { |response| responses << response }
    client.async_get('/path', { 'x-custom-header' => 'custom' }, timeout: 1) { |response| responses << response }

    wait_for { responses.length == 2 }

    expect(responses).to match_array [nil, nil]
  end

  it "returns nil when no concurrent responses are received within the specified timeout" do
    responses = []
    thread    = Thread.new do
      client.async_get('/path', { 'x-custom-header' => 'custom' }, timeout: 1) { |response| responses << response }
    end
    client.async_get('/path', { 'x-custom-header' => 'custom' }, timeout: 1) { |response| responses << response }

    thread.join

    wait_for { responses.length == 2 }

    expect(responses).to match_array [nil, nil]
  end
end

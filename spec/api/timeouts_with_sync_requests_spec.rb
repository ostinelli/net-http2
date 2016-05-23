require 'spec_helper'

describe "Timeouts with sync requests" do
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
    response = client.call(:get, '/path', headers: { 'x-custom-header' => 'custom' }, timeout: 1)

    expect(response).to be_nil
  end

  it "returns nil when no sequential responses are received within the specified timeout" do
    responses = []
    responses << client.call(:get, '/path', headers: { 'x-custom-header' => 'custom' }, timeout: 1)
    responses << client.call(:get, '/path', headers: { 'x-custom-header' => 'custom' }, timeout: 1)

    expect(responses.compact).to be_empty
  end

  it "returns nil when no concurrent responses are received within the specified timeout" do
    started_at = Time.now

    responses = []
    thread    = Thread.new { responses << client.call(:get, '/path', headers: { 'x-custom-header' => 'custom' }, timeout: 1) }
    responses << client.call(:get, '/path', headers: { 'x-custom-header' => 'custom' }, timeout: 1)

    thread.join

    time_taken = Time.now - started_at
    expect(time_taken < 2).to eq true

    expect(responses.compact).to be_empty
  end

  it "returns nil even if the client's main thread gets killed" do

    Thread.new do
      sleep 1
      client.close
    end

    response = client.call(:get, '/path', headers: { 'x-custom-header' => 'custom' }, timeout: 2)
    expect(response).to be_nil
  end
end

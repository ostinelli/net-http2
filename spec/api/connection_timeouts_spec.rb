require 'spec_helper'

describe "Timeouts during connection" do
  let(:port) { 9516 }
  let(:client) do
    NetHttp2::Client.new(
      "#{scheme}://10.255.255.1:#{port}", # non-routable IP address to simulate timeout
      connect_timeout: 1
    )
  end

  context "on non-SSL connections" do
    let(:scheme) { 'http' }

    it "raises after the custom timeout on tcp connections" do
      started_at = Time.now

      response = client.call(:get, '/path') rescue Errno::ETIMEDOUT

      expect(response).to eq Errno::ETIMEDOUT

      time_taken = Time.now - started_at
      expect(time_taken < 2).to eq true
    end
  end

  context "on SSL connections" do
    let(:scheme) { 'https' }

    it "raises after the custom timeout on SSL connections" do
      started_at = Time.now

      response = client.call(:get, '/path') rescue Errno::ETIMEDOUT

      expect(response).to eq Errno::ETIMEDOUT

      time_taken = Time.now - started_at
      expect(time_taken < 2).to eq true
    end
  end
end

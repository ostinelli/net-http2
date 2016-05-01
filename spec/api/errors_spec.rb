require 'spec_helper'

describe "Errors" do
  let(:port) { 9516 }
  let(:server) { NetHttp2::Dummy::Server.new(port: port) }
  let(:client) { NetHttp2::Client.new("http://localhost:#{port}") }

  describe "Errors in callbacks" do

    before { server.listen }
    after do
      client.close
      server.stop
    end

    [
      :headers,
      :body_chunk,
      :close
    ].each do |event|

      it "does not silently fail if errors are raised in the #{event} event" do
        request = client.prepare_request(:get, '/path')

        event_triggered = false
        request.on(:headers) do |_hs|
          event_triggered = true
          raise "error while processing event #{event}"
        end

        client.call_async(request)

        expect { wait_for { event_triggered } }.to raise_error "error while processing event #{event}"
      end
    end
  end

  describe "Errors in sockets" do

    it "raise errors" do
      expect { client.call(:get, '/path') }.to raise_error Errno::ECONNREFUSED
    end
  end
end

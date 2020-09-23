require 'spec_helper'

describe "Errors" do
  let(:port) { 9516 }
  let(:server) { NetHttp2::Dummy::Server.new(port: port, ssl: true) }
  let(:client) { NetHttp2::Client.new("https://localhost:#{port}") }

  describe "Sync calls" do
    describe "Connection errors" do

      context "when :error callback is not defined" do

        it "raise errors when server cannot be reached" do
          expect { client.call(:get, '/path') }.to raise_error Errno::ECONNREFUSED
        end
      end

      context "when :error callback is defined" do

        before do
          client.on(:error) { |_exc| nil }
        end

        it "raise errors when server cannot be reached" do
          expect { client.call(:get, '/path') }.to raise_error Errno::ECONNREFUSED
        end
      end
    end

    describe "EOFErrors on socket" do

      before { server.listen }
      after do
        client.close
        server.stop
      end

      context "when :error callback is not defined" do

        it "raises a SocketError" do
          server.on_req = Proc.new do |_req, _stream, socket|
            socket.close
          end

          expect { client.call(:get, '/path') }.to raise_error SocketError, 'Socket was remotely closed'
        end

        it "repairs the connection for subsequent calls" do
          close_next_socket = true
          server.on_req     = Proc.new do |_req, _stream, socket|
            if close_next_socket
              close_next_socket = false
              socket.close
            else
              NetHttp2::Response.new(
                headers: { ":status" => "200" },
                body:    "response body"
              )
            end
          end

          client.call(:get, '/path') rescue SocketError

          response = client.call(:get, '/path')
          expect(response.status).to eq '200'
          expect(response.body).to eq 'response body'
        end
      end

      context "when :error callback is defined" do

        before do
          @exception = nil
          client.on(:error) do |exc|
            @exception = exc
          end
        end

        it "calls the :error callback" do
          server.on_req = Proc.new do |_req, _stream, socket|
            socket.close
          end

          request = client.prepare_request(:get, '/path')

          client.call_async(request)
          client.join

          expect(@exception).to be_a SocketError
          expect(@exception.message).to eq 'Socket was remotely closed'
        end

        it "repairs the connection for subsequent calls" do
          close_next_socket = true
          server.on_req     = Proc.new do |_req, _stream, socket|
            if close_next_socket
              close_next_socket = false
              socket.close
            else
              NetHttp2::Response.new(
                headers: { ":status" => "200" },
                body:    "response body"
              )
            end
          end

          request = client.prepare_request(:get, '/path')
          client.call_async(request)
          client.join

          headers   = nil
          body      = ''
          completed = false
          request   = client.prepare_request(:get, '/path')
          request.on(:headers) { |hs| headers = hs }
          request.on(:body_chunk) { |chunk| body << chunk }
          request.on(:close) { completed = true }

          client.call_async(request)
          client.join

          expect(headers).to_not be_nil
          expect(headers[':status']).to eq "200"
          expect(headers['content-length']).to eq "13"

          expect(body).to eq "response body"

          expect(completed).to eq true
        end
      end
    end
  end

  describe "Async calls" do

    describe "Connection errors" do

      context "when :error callback is not defined" do

        it "raise errors when server cannot be reached" do
          request = client.prepare_request(:get, '/path')

          expect { client.call_async(request) }.to raise_error Errno::ECONNREFUSED
        end
      end

      context "when :error callback is defined" do

        before do
          client.on(:error) { |_exc| nil }
        end

        it "raise errors when server cannot be reached" do
          request = client.prepare_request(:get, '/path')

          expect { client.call_async(request) }.to raise_error Errno::ECONNREFUSED
        end
      end
    end

    describe "unfinished requests" do

      before { server.listen }
      after do
        client.close
        server.stop
      end

      it "times out joining the client" do
        server.on_req = Proc.new do |_req, _stream, socket|
          sleep 2

          NetHttp2::Response.new(
            headers: { ":status" => "200" },
            body:    "response body"
          )
        end

        request = client.prepare_request(:get, '/path')

        client.call_async(request)
        expect { client.join(timeout: 1) }.to raise_error NetHttp2::AsyncRequestTimeout
        client.join
      end
    end

    describe "EOFErrors on socket" do

      before { server.listen }
      after do
        client.close
        server.stop
      end

      context "when :error callback is defined" do

        before do
          @exception = nil
          client.on(:error) do |exc|
            @exception = exc
          end
        end

        it "calls the :error callback" do
          server.on_req = Proc.new do |_req, _stream, socket|
            socket.close
          end

          request = client.prepare_request(:get, '/path')

          client.call_async(request)
          client.join

          expect(@exception).to be_a SocketError
          expect(@exception.message).to eq 'Socket was remotely closed'
        end

        it "repairs the connection for subsequent calls" do
          close_next_socket = true
          server.on_req     = Proc.new do |_req, _stream, socket|
            if close_next_socket
              close_next_socket = false
              socket.close
            else
              NetHttp2::Response.new(
                headers: { ":status" => "200" },
                body:    "response body"
              )
            end
          end

          request = client.prepare_request(:get, '/path')
          client.call_async(request)
          client.join

          headers   = nil
          body      = ''
          completed = false
          request   = client.prepare_request(:get, '/path')
          request.on(:headers) { |hs| headers = hs }
          request.on(:body_chunk) { |chunk| body << chunk }
          request.on(:close) { completed = true }

          client.call_async(request)
          client.join

          expect(headers).to_not be_nil
          expect(headers[':status']).to eq "200"
          expect(headers['content-length']).to eq "13"

          expect(body).to eq "response body"

          expect(completed).to eq true
        end
      end

      context "when :error callback is not defined" do

        it "raises a SocketError in main thread" do
          server.on_req = Proc.new do |_req, _stream, socket|
            socket.close
          end

          request = client.prepare_request(:get, '/path')

          event_triggered = false
          request.on(:headers) do |_hs|
            event_triggered = true
            raise "error while processing event #{event}"
          end

          client.call_async(request)

          expect { wait_for { event_triggered } }.to raise_error SocketError, 'Socket was remotely closed'
        end

        it "repairs the connection for subsequent calls" do
          close_next_socket = true
          server.on_req     = Proc.new do |_req, _stream, socket|
            if close_next_socket
              close_next_socket = false
              socket.close
            else
              NetHttp2::Response.new(
                headers: { ":status" => "200" },
                body:    "response body"
              )
            end
          end

          request = client.prepare_request(:get, '/path')

          event_triggered = false
          request.on(:headers) do |_hs|
            event_triggered = true
            raise "error while processing event #{event}"
          end

          client.call_async(request)
          wait_for { event_triggered } rescue SocketError

          headers   = nil
          body      = ''
          completed = false
          request   = client.prepare_request(:get, '/path')
          request.on(:headers) { |hs| headers = hs }
          request.on(:body_chunk) { |chunk| body << chunk }
          request.on(:close) { completed = true }

          client.call_async(request)
          client.join

          expect(headers).to_not be_nil
          expect(headers[':status']).to eq "200"
          expect(headers['content-length']).to eq "13"

          expect(body).to eq "response body"

          expect(completed).to eq true
        end
      end
    end

    describe "Errors in callbacks" do

      before { server.listen }
      after do
        client.close
        server.stop
      end

      [
        :headers,
        :body_chunk,
      # :close TODO: remove this
      ].each do |event|

        it "does not silently fail if errors are raised in the #{event} event" do
          request = client.prepare_request(:get, '/path')

          event_triggered = false
          request.on(event) do |_hs|
            event_triggered = true
            raise "error while processing event :#{event}"
          end

          client.call_async(request)

          expect { wait_for { event_triggered } }.to raise_error "error while processing event :#{event}"
        end
      end
    end
  end
end

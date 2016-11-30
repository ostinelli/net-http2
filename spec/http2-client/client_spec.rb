require 'spec_helper'

describe NetHttp2::Client do

  describe "attributes" do
    let(:client) { NetHttp2::Client.new("http://localhost") }
    subject { client }
    it { is_expected.to have_attributes(uri: URI.parse("http://localhost")) }
  end

  describe "options" do

    describe "npm protocols in SSL" do

      subject { client.instance_variable_get(:@ssl_context) }

      context "when no custom SSL context is passed in" do
        let(:client) { NetHttp2::Client.new("http://localhost") }

        it "specifies the DRAFT protocol" do
          expect(subject.npn_protocols).to eq ['h2']
        end
      end
      context "when a custom SSL context is passed in" do
        let(:ssl_context) { OpenSSL::SSL::SSLContext.new }
        let(:client) { NetHttp2::Client.new("http://localhost", ssl_context: ssl_context) }

        it "specifies the DRAFT protocol" do
          expect(subject.npn_protocols).to eq ['h2']
          expect(ssl_context.npn_protocols).to eq ['h2']
        end
      end
    end
  end

  describe "#ssl?" do
    let(:client) { NetHttp2::Client.new(url) }

    subject { client.ssl? }

    context "when URL has an http scheme" do
      let(:url) { "http://localhost" }
      it { is_expected.to eq false }
    end

    context "when URL has an https scheme" do
      let(:url) { "https://localhost" }
      it { is_expected.to eq true }
    end
  end

  describe '#proxy_tcp_socket' do
    let(:target_location) { 'bigbrother.com' }
    let(:target_port) { '9999' }
    let(:uri) { URI.parse("https://#{target_location}:#{target_port}") }
    let(:options) {
      {
        ssl_context: OpenSSL::SSL::SSLContext.new,
        proxy_addr: 'http://hidemyass.proxy.com',
        proxy_port: '3213',
        proxy_user: 'someuser',
        proxy_pass: 'somepass'
      }
    }
    let(:fake_tcp_socket) { double }
    let(:fake_ssl_socket) { double(:sync_close= => 'ok', :connect => 'ok') }

    it 'establish connection through proxy with credentials' do
      expect(OpenSSL::SSL::SSLSocket).to receive(:new) { fake_ssl_socket }
      expect(NetHttp2::Socket).to receive(:tcp_socket).
        with(URI.parse("#{options[:proxy_addr]}:#{options[:proxy_port]}"), options).
        exactly(:once) { fake_tcp_socket }
      expect(fake_tcp_socket).to receive(:write).with(
        "CONNECT #{target_location}:#{target_port} HTTP/1.1\r\n"\
          "Host: #{target_location}:#{target_port}\r\n"\
          "Proxy-Authorization: Basic c29tZXVzZXI6c29tZXBhc3M=\r\n\r\n"
      )
      expect(fake_tcp_socket).to receive(:gets).
        and_return('HTTP/1.1 200 OK', '')
      expect(fake_ssl_socket).to receive(:hostname=).with(options[:proxy_addr])

      NetHttp2::Socket.ssl_socket(uri, options)
    end
  end
end

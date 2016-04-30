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
end

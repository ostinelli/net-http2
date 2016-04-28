require 'spec_helper'

describe NetHttp2::Request::Get do
  let(:uri) { URI.parse("http://localhost") }
  let(:path) { "/path" }
  let(:headers) { {} }
  let(:options) { {} }
  let(:request) { NetHttp2::Request::Get.new(uri, path, headers, options) }

  describe "attributes" do

    subject { request }

    it { is_expected.to have_attributes(body: nil) }

    context "when timeout is passed in options" do
      let(:timeout) { double(:timeout) }
      let(:options) { { timeout: timeout } }

      it { is_expected.to have_attributes(timeout: timeout) }
    end

    context "when timeout is not passed in options" do
      it { is_expected.to have_attributes(timeout: 60) }
    end
  end

  describe "#headers" do

    subject { request.headers }

    context "when no headers are passed" do
      let(:headers) { {} }

      it { is_expected.to eq(
        {
          ':scheme' => 'http',
          ':method' => 'GET',
          ':path'   => '/path',
          'host'    => 'localhost'
        }
      ) }
    end

    context "when headers are passed" do
      let(:headers) do
        {
          ':scheme'  => 'https',
          ':method'  => 'OTHER',
          ':path'    => '/another',
          'host'     => 'rob.local',
          'x-custom' => 'custom'
        }
      end

      it { is_expected.to eq(
        {
          ':scheme'  => 'http',
          ':method'  => 'GET',
          ':path'    => '/path',
          'host'     => 'rob.local',
          'x-custom' => 'custom'
        }
      ) }
    end
  end
end

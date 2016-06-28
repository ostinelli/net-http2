require 'spec_helper'

describe NetHttp2::Request do
  let(:method) { :get }
  let(:uri) { URI.parse("http://localhost") }
  let(:path) { "/path" }
  let(:body) { "request body" }
  let(:headers) { {} }
  let(:timeout) { 5 }
  let(:request) do
    NetHttp2::Request.new(method, uri, path, headers: headers, body: body, timeout: timeout)
  end

  describe "attributes" do

    subject { request }

    it { is_expected.to have_attributes(method: method) }
    it { is_expected.to have_attributes(uri: uri) }
    it { is_expected.to have_attributes(path: path) }
    it { is_expected.to have_attributes(body: body) }
    it { is_expected.to have_attributes(timeout: timeout) }
  end

  describe "#headers" do

    subject { request.headers }

    context "when a body has been specified" do
      let(:method) { :post }
      let(:body) { "request body" }

      context "when no headers are passed" do
        let(:headers) { {} }

        it { is_expected.to eq(
          {
            ':scheme'        => 'http',
            ':method'        => 'POST',
            ':path'          => '/path',
            'host'           => 'localhost',
            'content-length' => '12'
          }
        ) }
      end

      context "when headers are passed" do
        let(:headers) do
          {
            ':scheme'        => 'https',
            ':method'        => 'OTHER',
            ':path'          => '/another',
            'host'           => 'rob.local',
            'x-custom'       => 'custom',
            'content-length' => '999'
          }
        end

        it { is_expected.to eq(
          {
            ':scheme'        => 'http',
            ':method'        => 'POST',
            ':path'          => '/path',
            'host'           => 'rob.local',
            'x-custom'       => 'custom',
            'content-length' => '12'
          }
        ) }
      end
    end

    context "when no body has been specified" do
      let(:method) { :get }
      let(:body) { nil }

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
            ':scheme'        => 'https',
            ':method'        => 'OTHER',
            ':path'          => '/another',
            'host'           => 'rob.local',
            'x-custom'       => 'custom',
            'content-length' => '999'
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

  describe "Events subscription & emission" do

    [
      :headers,
      :body_chunk,
      :close
    ].each do |event|
      it "subscribes and emits for event #{event}" do
        calls = []
        request.on(event) { calls << :one }
        request.on(event) { calls << :two }

        request.emit(event, "param")

        expect(calls).to match_array [:one, :two]
      end
    end
  end
end

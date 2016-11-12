require 'spec_helper'

describe NetHttp2::Request do
  let(:method) { :get }
  let(:uri) { URI.parse("http://localhost") }
  let(:path) { "/path" }
  let(:params) { { one: 1, two: 2 } }
  let(:body) { "request body" }
  let(:headers) { {} }
  let(:timeout) { 5 }
  let(:request) do
    NetHttp2::Request.new(method, uri, path, params: params, headers: headers, body: body, timeout: timeout)
  end

  describe "attributes" do

    subject { request }

    it { is_expected.to have_attributes(method: method) }
    it { is_expected.to have_attributes(uri: uri) }
    it { is_expected.to have_attributes(path: path) }
    it { is_expected.to have_attributes(params: params) }
    it { is_expected.to have_attributes(body: body) }
    it { is_expected.to have_attributes(timeout: timeout) }
  end

  describe "#headers" do
    let(:full_path) { double(:full_path) }

    before { allow(request).to receive(:full_path) { full_path } }

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
            ':path'          => full_path,
            ':authority'     => 'localhost:80',
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
            ':authority'     => 'rob.local:80',
            'x-custom'       => 'custom',
            'content-length' => '999'
          }
        end

        it { is_expected.to eq(
          {
            ':scheme'        => 'http',
            ':method'        => 'POST',
            ':path'          => full_path,
            ':authority'     => 'rob.local:80',
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
            ':scheme'    => 'http',
            ':method'    => 'GET',
            ':path'      => full_path,
            ':authority' => 'localhost:80'
          }
        ) }
      end

      context "when headers are passed" do
        let(:headers) do
          {
            ':scheme'        => 'https',
            ':method'        => 'OTHER',
            ':path'          => '/another',
            ':authority'     => 'rob.local:80',
            'x-custom'       => 'custom',
            'content-length' => '999'
          }
        end

        it { is_expected.to eq(
          {
            ':scheme'    => 'http',
            ':method'    => 'GET',
            ':path'      => full_path,
            ':authority' => 'rob.local:80',
            'x-custom'   => 'custom'
          }
        ) }
      end
    end
  end

  describe "#full_path" do

    def request_for_params(params)
      NetHttp2::Request.new(:get, 'http://example.com', '/my_path', params: params)
    end

    it "converts params into properly formed query strings" do
      request = request_for_params(a: "a", b: ["c", "d", "e"])
      expect(request.full_path).to eq "/my_path?a=a&b%5B%5D=c&b%5B%5D=d&b%5B%5D=e"

      request = request_for_params(a: "a", :b => [{ :c => "c", :d => "d" }, { :e => "e", :f => "f" }])
      expect(request.full_path).to eq "/my_path?a=a&b%5B%5D%5Bc%5D=c&b%5B%5D%5Bd%5D=d&b%5B%5D%5Be%5D=e&b%5B%5D%5Bf%5D=f"

      request = request_for_params(a: "a", :b => { :c => "c", :d => "d" })
      expect(request.full_path).to eq "/my_path?a=a&b%5Bc%5D=c&b%5Bd%5D=d"

      request = request_for_params(a: "a", :b => { :c => "c", :d => true })
      expect(request.full_path).to eq "/my_path?a=a&b%5Bc%5D=c&b%5Bd%5D=true"

      request = request_for_params(a: "a", :b => { :c => "c", :d => true }, :e => [])
      expect(request.full_path).to eq "/my_path?a=a&b%5Bc%5D=c&b%5Bd%5D=true"

      request = request_for_params(nil)
      expect(request.full_path).to eq "/my_path"
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

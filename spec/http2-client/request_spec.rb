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
    let(:full_path) { '/a/full/path' }

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
            ':scheme'         => 'https',
            ':method'         => 'OTHER',
            ':path'           => '/another',
            ':authority'      => 'rob.local:80',
            'x-custom'        => 'custom',
            'x-custom-number' => 3,
            'content-length'  => '999'
          }
        end

        it { is_expected.to eq(
          {
            ':scheme'         => 'http',
            ':method'         => 'POST',
            ':path'           => full_path,
            ':authority'      => 'rob.local:80',
            'x-custom'        => 'custom',
            'x-custom-number' => '3',
            'content-length'  => '12'
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
            ':scheme'         => 'https',
            ':method'         => 'OTHER',
            ':path'           => '/another',
            ':authority'      => 'rob.local:80',
            'x-custom'        => 'custom',
            'x-custom-number' => 3,
            'content-length'  => '999'
          }
        end

        it { is_expected.to eq(
          {
            ':scheme'         => 'http',
            ':method'         => 'GET',
            ':path'           => full_path,
            ':authority'      => 'rob.local:80',
            'x-custom'        => 'custom',
            'x-custom-number' => '3'
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
      req = request_for_params(a: "a", b: ["c", "d", "e"])
      expect(req.full_path).to eq "/my_path?a=a&b%5B%5D=c&b%5B%5D=d&b%5B%5D=e"

      req = request_for_params(a: "a", :b => [{ :c => "c", :d => "d" }, { :e => "e", :f => "f" }])
      expect(req.full_path).to eq "/my_path?a=a&b%5B%5D%5Bc%5D=c&b%5B%5D%5Bd%5D=d&b%5B%5D%5Be%5D=e&b%5B%5D%5Bf%5D=f"

      req = request_for_params(a: "a", :b => { :c => "c", :d => "d" })
      expect(req.full_path).to eq "/my_path?a=a&b%5Bc%5D=c&b%5Bd%5D=d"

      req = request_for_params(a: "a", :b => { :c => "c", :d => true })
      expect(req.full_path).to eq "/my_path?a=a&b%5Bc%5D=c&b%5Bd%5D=true"

      req = request_for_params(a: "a", :b => { :c => "c", :d => true }, :e => [])
      expect(req.full_path).to eq "/my_path?a=a&b%5Bc%5D=c&b%5Bd%5D=true"

      req = request_for_params(nil)
      expect(req.full_path).to eq "/my_path"
    end
  end

  describe "Subscription & emission" do
    subject { NetHttp2::Client.new("http://localhost") }
    it_behaves_like "a class that implements events subscription & emission"
  end
end

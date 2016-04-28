shared_examples_for "a NetHttp2 Request with a body" do |spec_opts={}|
  let(:uri) { URI.parse("http://localhost") }
  let(:path) { "/path" }
  let(:body) { "request body" }
  let(:headers) { {} }
  let(:options) { {} }
  let(:request) { described_class.new(uri, path, body, headers, options) }

  describe "attributes" do

    subject { request }

    it { is_expected.to have_attributes(uri: uri) }
    it { is_expected.to have_attributes(path: path) }
    it { is_expected.to have_attributes(body: body) }

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
          ':scheme'        => 'http',
          ':method'        => spec_opts[:method],
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
          ':method'        => spec_opts[:method],
          ':path'          => '/path',
          'host'           => 'rob.local',
          'x-custom'       => 'custom',
          'content-length' => '12'
        }
      ) }
    end
  end
end

shared_examples_for "a NetHttp2 Request with no body" do |spec_opts={}|
  let(:uri) { URI.parse("http://localhost") }
  let(:path) { "/path" }
  let(:headers) { {} }
  let(:options) { {} }
  let(:request) { described_class.new(uri, path, headers, options) }

  describe "attributes" do

    subject { request }

    it { is_expected.to have_attributes(uri: uri) }
    it { is_expected.to have_attributes(path: path) }
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
          ':method' => spec_opts[:method],
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
          ':method'  => spec_opts[:method],
          ':path'    => '/path',
          'host'     => 'rob.local',
          'x-custom' => 'custom'
        }
      ) }
    end
  end
end
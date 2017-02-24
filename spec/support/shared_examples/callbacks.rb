shared_examples_for "a class that implements events subscription & emission" do |options={}|

  describe "Events subscription & emission" do

    [
      :headers,
      :body_chunk,
      :close
    ].each do |event|
      it "subscribes and emits for event #{event}" do
        calls = []
        subject.on(event) { calls << :one }
        subject.on(event) { calls << :two }

        subject.emit(event, "param")

        expect(calls).to match_array [:one, :two]
      end
    end
  end
end

module NetHttp2

  module ApiHelpers

    def wait_for(seconds=2, &block)
      (0..seconds).each do
        break if block.call
        sleep 1
      end
    end
  end
end

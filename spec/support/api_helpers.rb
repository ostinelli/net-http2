module NetHttp2

  module ApiHelpers
    WAIT_INTERVAL = 1

    def wait_for(seconds=2, &block)
      count = 1 / WAIT_INTERVAL

      (0..(count * seconds)).each do
        break if block.call
        sleep WAIT_INTERVAL
      end
    end
  end
end

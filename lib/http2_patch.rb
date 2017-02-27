require 'http/2/connection'

# We are currently locked to using the Http2 library v0.8.2 since v0.8.3 still has some compatibility issues:
# <https://github.com/igrigorik/http-2/issues/92>
#
# However, v0.8.2 had a memory leak that was reported in the following issues:
# <https://github.com/igrigorik/http-2/issues/73>
# <https://github.com/ostinelli/net-http2/issues/7>
#
# Hence, this is a temporary monkey-patch to the HTTP2 library in order to solve the mentioned leak
# while waiting to fix the issues on v0.8.3.

module HTTP2

  class Connection

    private

    def activate_stream(id: nil, **args)
      connection_error(msg: 'Stream ID already exists') if @streams.key?(id)

      stream = Stream.new({ connection: self, id: id }.merge(args))

      # Streams that are in the "open" state, or either of the "half closed"
      # states count toward the maximum number of streams that an endpoint is
      # permitted to open.
      stream.once(:active) { @active_stream_count += 1 }

      @streams_recently_closed ||= {}
      stream.once(:close) do
        @active_stream_count -= 1

        @streams_recently_closed.delete_if do |closed_stream_id, v|
          to_be_deleted = (Time.now - v) > 15
          @streams.delete(closed_stream_id) if to_be_deleted
          to_be_deleted
        end

        @streams_recently_closed[id] = Time.now
      end

      stream.on(:promise, &method(:promise)) if self.is_a? Server
      stream.on(:frame, &method(:send))
      stream.on(:window_update, &method(:window_update))

      @streams[id] = stream
    end
  end
end

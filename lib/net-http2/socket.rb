module NetHttp2

  module Socket

    def self.create(uri, options)
      options[:ssl] ? ssl_socket(uri, options) : tcp_socket(uri, options)
    end

    def self.ssl_socket(uri, options)
      tcp = tcp_socket(uri, options)

      socket            = OpenSSL::SSL::SSLSocket.new(tcp, options[:ssl_context])
      socket.sync_close = true
      socket.hostname   = uri.hostname

      socket.connect

      socket
    end

    def self.tcp_socket(uri, options)
      family   = ::Socket::AF_INET
      address  = ::Socket.getaddrinfo(uri.host, nil, family).first[3]
      sockaddr = ::Socket.pack_sockaddr_in(uri.port, address)

      socket = ::Socket.new(family, ::Socket::SOCK_STREAM, 0)
      socket.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)

      begin
        socket.connect_nonblock(sockaddr)
      rescue IO::WaitWritable
        if IO.select(nil, [socket], nil, options[:connect_timeout])
          begin
            socket.connect_nonblock(sockaddr)
          rescue Errno::EISCONN
            # socket is connected
          rescue
            socket.close
            raise
          end
        else
          socket.close
          raise Errno::ETIMEDOUT
        end
      end

      socket
    end
  end
end

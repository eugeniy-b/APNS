module APNS
  class Feedback
    def self.feedback_connection
      raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless APNS::Config.pem
      raise "The path to your pem file does not exist!" unless File.exist?(APNS::Config.pem)

      context      = OpenSSL::SSL::SSLContext.new
      context.cert = OpenSSL::X509::Certificate.new(File.read(APNS::Config.pem))
      context.key  = OpenSSL::PKey::RSA.new(File.read(APNS::Config.pem), APNS::Config.pass)
      fhost        = APNS::Config.host.gsub!('gateway', 'feedback')
      sock         = TCPSocket.new(fhost, 2196)
      ssl          = OpenSSL::SSL::SSLSocket.new(sock, context)
      ssl.sync = true

      begin
        ssl.connect_nonblock
      rescue IO::WaitReadable
        if IO.select([ssl], nil, nil, 5)
          retry
        else
          raise
        end
      rescue IO::WaitWritable
        if IO.select(nil, [ssl], nil, 5)
          retry
        else
          raise
        end
      end

      return sock, ssl
    end

    def self.feedback
      sock, ssl = self.feedback_connection

      apns_feedback = []

      while data = ssl.read(38)
        apns_feedback << self.parse_feedback_tuple(data)
      end

      ssl.close
      sock.close

      return apns_feedback
    end

    def self.parse_feedback_tuple(data)
      feedback = data.unpack('N1n1H*')
      {
        :feedback_at => Time.at(feedback[0]),
        :length => feedback[1],
        :device_token => feedback[2]
      }
    end
  end
end

module APNS
  class Config
    @host = 'gateway.sandbox.push.apple.com'
    @port = 2195
    # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
    @pem  = nil # this should be the path of the pem file not the content's
    @pass = nil

    INSTANCE = Config.new

    class << self
      attr_accessor :host, :pem, :port, :pass
    end

    def self.instance
      INSTANCE
    end
  end
end
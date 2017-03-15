module APNS
  class PayloadNotification < Notification
    attr_accessor :payload

    def initialize(device_token, payload)
      self.device_token = device_token
      self.payload = payload
    end

    def packaged_message
      payload
    end
  end
end

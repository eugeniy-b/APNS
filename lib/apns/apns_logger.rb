# Provide some logging to the apns lib using the inbuilt 'logger'
module APNS
  # Main class hosting all the logic functionality. Host a single Logger instance and force every logging request
  # to go through it.
  class ApnsLogger
    require 'logger'

    LOGGER_INSTANCE = Logger.new(STDOUT)
    LOGGER_INSTANCE.level = Logger::DEBUG
    #LOGGER_INSTANCE.datetime_format = "%Y-%m-%d %H:%M:%S"
    #APNS_LOGGER_INSTANCE = ApnsLogger.new

    # get the logger instance
    def self.log
      APNS::Config.logger.nil? ? LOGGER_INSTANCE : APNS::Config.logger
    end

    # redirect all calls to methods, to the logger instance
    def method_missing(m, *args, &block)
      fm = "[#{Time.now.strftime("%m/%d/%Y-%I:%M%p %Z")}] [#{m.to_s}] #{args[0].to_s}"
      LOGGER_INSTANCE.send(m, APP_NAME) {fm}
    end
  end
end

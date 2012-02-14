# Provide some logging to the apns lib using the inbuilt 'logger'
module APNS
  # Main class hosting all the logic functionality. Host a single Logger instance and force every logging request
  # to go through it.
  class ApnsLogger
    require 'logger'

    APP_NAME = "apns_lib"
    `mkdir -p log` # create a log directory if it does not exist
    LOGGER_INSTANCE = Logger.new("log/#{APP_NAME}.log", 1000, 1024000) # log to a file, limit to 1MB/(rotate) 1000 files
    #LOGGER_INSTANCE = Logger.new(STDOUT) # log to the std out
    LOGGER_INSTANCE.level = Logger::DEBUG
    #LOGGER_INSTANCE.datetime_format = "%Y-%m-%d %H:%M:%S"
    APNS_LOGGER_INSTANCE = ApnsLogger.new

    # get the logger instance
    def self.log
      APNS_LOGGER_INSTANCE
    end

    # redirect all calls to methods, to the logger instance
    def method_missing(m, *args, &block)
	    fm = "[#{Time.now.strftime("%m/%d/%Y-%I:%M%p %Z")}] [#{m.to_s}] #{args[0].to_s}"
      LOGGER_INSTANCE.send(m, APP_NAME) {fm}
    end

    def log_array title, array_to_log
      info title
      array_to_log.each do |item|
        info item
      end
    end
  end
end

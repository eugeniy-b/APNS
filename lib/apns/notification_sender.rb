module APNS
  class NotificationSender
    require 'json'

    def self.send_notification(device_token, message, connection_provider=APNS::ConnectionProvider, error_code_handler=APNS::ApnsErrorCodeHandler)
      begin
        sock, ssl = connection_provider.open_connection
        ssl.write(APNS::Notification.new(device_token, message).packaged_notification(0))
        error = error_code_handler.get_error_if_present ssl
        APNS::ApnsLogger.log.info("error received from the APNS: #{error}") if error
      rescue Exception => ex
        APNS::ApnsLogger.log.fatal "Exception in send_notification. device_token: #{device_token} message: #{message}"
        APNS::ApnsLogger.log.fatal(error = ex)
      ensure
        #do a couple of checks to see if both ssl and sock are null.
        if ssl
          ssl.close
        else
          APNS::ApnsLogger.log.warn("ssl socket was null when trying to close it")
        end

        if sock
          sock.close
        else
          APNS::ApnsLogger.log.warn("tcp socket was null when trying to close it")
        end
      end
      error
    end

    # Checks whether the APNS have sent any error messages through the connection. If any errors are present,
    # edit the state map, as necessary so that notification sending can be started from the point after the failed
    # notification. (the number of notifications is taken to consideration as well. so if the last notification that was
    # sent have failed, this method would return false, as there are no notifications left for the notification sending
    # process to continue.
    #
    # Send true if the notification sending process should continue (manning errors were found). Send false if
    # the notification process should not continue (meaning that no errors were found).
    def self.continue_notification_sending?(
        state, ssl, notifications,
            error_code_handler=APNS::ApnsErrorCodeHandler,
            logger=APNS::ApnsLogger.log
    )
      if error = error_code_handler.get_error_if_present(ssl)
        logger.warn "Error detected in continue_notification_sending?"
        logger.warn error
        
        # record the failure to send this notification, that failed
        state[:failures] << {
          :token => notifications[error[:notification_id]].device_token,
          :error => error
        } if error[:notification_id]
      end

      state[:start_point] < notifications.size
    end

    # send a batch of notifications. Uses the enhanced notification format. return a array with all errors encountered while
    # sending the given batch of notifications
    #
    # return array format
    # [{:token => 112894699s8d7f9sdf79s81237199, :error => {}},...]
    #
    # the :error contains a APNS::ApnsErrorCodeHandler.get_error_if_present returned map representing a APNS returned error
    def self.send_notifications notifications, connection_provider=APNS::ConnectionProvider
      state = {
          :start_point => 0,
          :failures => []
      }

      while true do
        begin
          # get the connection
          sock, ssl = connection_provider.open_connection

          # start sending notifications
          for i in state[:start_point]..(notifications.size - 1)
            ssl.write(notifications[i].packaged_notification(i))
            state[:start_point] += 1
            # sleep(1) #use this for testing the rescue Errno::EPIPE block. As when you only have a small number of notifications
            #the rescue block never gets executed as it takes a while for the APNS to send a error
            #through the pipe and disconnect you.
          end

          if !self.continue_notification_sending?(state, ssl, notifications)
            break
          end

        rescue Errno::EPIPE, Errno::ETIMEDOUT, Errno::ECONNRESET => exception # this is the classic error when APNS drops the connection...
          APNS::ApnsLogger.log.warn "Connection exception in send_notifications"
          APNS::ApnsLogger.log.warn exception
          # try to get the error message sent by the APNS. This should be present if the connection was
          # dropped by the APNS because of a error in a sent notification.
          break unless self.continue_notification_sending?(state, ssl, notifications)
            
        rescue Exception => exception # whatever other errors goes here
          APNS::ApnsLogger.log.fatal "Exception in send_notifications"
          APNS::ApnsLogger.log.fatal exception
          break #this is a unexpected situation. We don't know what notifications got sent and what didn't. so just giveup.
        
        ensure # make sure we close the connections whatever happens
          #do a couple of checks to see if both ssl and sock are null.
          if ssl
            ssl.close
          else
            APNS::ApnsLogger.log.warn("ssl socket was null when trying to close it")
          end

          if sock
            sock.close
          else
            APNS::ApnsLogger.log.warn("tcp socket was null when trying to close it")
          end
        end
      end

      state[:failures]
    end
  end
end

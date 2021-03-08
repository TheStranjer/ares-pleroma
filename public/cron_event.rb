module AresMUSH
  module Pleroma
    class CronEventHandler
      attr_accessor :event

      def on_event(event)
        @event = event

        Global.client_monitor.logged_in_clients.each do |client|
          handle(client)
        end
      end

      private

      def handle(client)
        return if client.char.pleroma_bearer_token.nil?

        path = "/api/v1/notifications?with_muted=true&limit=20&since_id=#{client.char.pleroma_last_notification_id.to_i}"

        response = Pleroma::request(path: path, method: :get, bearer_token: client.char.pleroma_bearer_token)

        response.each do |notif|
          Global.dispatcher.queue_event FediverseResponseEvent.new(notif, client)

          type = notif['type']
          acct = notif['account']['fqn']

          case type
          when 'reblog'
            client.emit t('pleroma.user_reblogged', account: acct)
          when 'follow'
            client.emit t('pleroma.user_followed', account: acct)
          when 'mention'
            client.emit t('pleroma.user_mentioned', account: acct, message: notif['status']['pleroma']['content']['text/plain'])
          when 'favourite'
            client.emit t('pleroma.user_liked', account: acct)
          else
            client.emit type
          end

          if client.char.pleroma_last_notification_id.nil?
            client.char.update(:pleroma_last_notification_id => notif['id'].to_i)
          elsif client.char.pleroma_last_notification_id.to_i < notif['id'].to_i
            client.char.update(:pleroma_last_notification_id => notif['id'].to_i)
          end

          client.char.save
        end
      end
    end
  end
end

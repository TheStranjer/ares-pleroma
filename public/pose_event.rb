require 'net/http'
require 'uri'
require 'json'

module AresMUSH
  module Pleroma
    class PoseEventHandler
      attr_accessor :event, :char, :scene

      def on_event(event)
        @event = event
        @char = Character.find_one_by_name(event.enactor_id)
        @scene = Room[event.room_id].scene

        return if scene.completed or scene.is_private?

        ensure_pleroma_account_exists
        ensure_pleroma_bearer_token

        submit_pose
      end

      private

      def ensure_pleroma_account_exists
        return if char.pleroma_username

        password_chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
        password = ""
        rand(15..30).times { password += password_chars.sample }

        Pleroma::request(path: "/api/pleroma/admin/users", body: {'users': [{'nickname': char.name, 'email': "#{char.name}@#{Global.read_config('pleroma', 'instance_domain')}", 'password': password }]})

        char.update(:pleroma_username => char.name, :pleroma_password => password)
        char.save
      end

      def ensure_pleroma_bearer_token
        return if char.pleroma_bearer_token

        client_info = Pleroma::request(path: "/api/v1/apps", body: {'client_name': 'AresMUSH Pleroma', 'redirect_uris': "https://#{Pleroma::instance}/oauth-callback", 'scopes': 'read write follow push admin'})

        bearer_info = Pleroma::request(path: "/oauth/token", body: { 'username': char.pleroma_username, 'password': char.pleroma_password, 'client_id': client_info['client_id'], 'client_secret': client_info['client_secret'], 'grant_type': 'password' })

        char.update(:pleroma_bearer_token => bearer_info['access_token'])
        char.save
      end

      def submit_pose
        body = { :status => event.pose.gsub("%r", "\n").gsub(/\%x\w/, ""), :visibility => "public" }
        
        previous_pose = scene.poses_in_order[-2]

        body[:in_reply_to_id] = previous_pose.pleroma_post_id if previous_pose and previous_pose.pleroma_post_id

        response = Pleroma::request(path: "/api/v1/statuses", body: body, bearer_token: char.pleroma_bearer_token)

        current_pose = scene.poses_in_order[-1]
        current_pose.update(:pleroma_post_id => response['id'])
        current_pose.save
      end
    end
  end
end

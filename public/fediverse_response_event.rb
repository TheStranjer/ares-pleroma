module AresMUSH
  module Pleroma
    class FediverseResponseEvent
      attr_reader :response, :client

      def initialize(response, client)
        @response = response
        @client = client
      end

      def type
        response['type']
      end

      def account_name
        response['account']
      end

      def char
        client.char
      end
    end
  end
end

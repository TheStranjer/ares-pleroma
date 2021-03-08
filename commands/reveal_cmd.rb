module AresMUSH
  module Pleroma
    class RevealCmd
      include CommandHandler

      attr_accessor :target

      def parse_args
        @target = cmd.args.nil? ? enactor : Character.find(:name_upcase => cmd.args.upcase).first
      end

      def check_character_exists
        t('demiurge.sheet.errors.does_not_exist', :char => cmd.args) if target.nil?
      end

      def check_role
        t('demiurge.sheet.errors.access_denied') if enactor.id != target.id and !enactor.has_any_role?(['coder', 'admin'])
      end

      def handle
        client.emit t('pleroma.reveal', :username => target.pleroma_username, :password => target.pleroma_password, :instance => Pleroma::instance)
      end
    end
  end
end

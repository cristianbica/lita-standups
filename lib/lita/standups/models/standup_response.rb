module Lita
  module Standups
    module Models
      class StandupResponse < Ohm::Model

        include Ohm::Callbacks
        include Ohm::Timestamps
        include Ohm::DataTypes

        attribute :status
        attribute :user_id
        attribute :answers, Type::Array

        reference :standup_session, StandupSession

        def user
          @user ||= Lita::User.fuzzy_find(user_id)
        end

        def before_create
          self.status = 'pending'
        end

        def after_save
          standup_session.update_status if finished?
        end

        %w(pending running completed aborted expired).each do |status_name|
          define_method("#{status_name}?") do
            status == status_name
          end
          define_method("#{status_name}!") do
            self.status = status_name
          end
        end

        def finished?
          completed? || aborted? || expired?
        end
      end
    end
  end
end

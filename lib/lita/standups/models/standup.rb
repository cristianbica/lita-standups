module Lita
  module Standups
    module Models
      class Standup < Ohm::Model

        include Ohm::Callbacks
        include Ohm::Timestamps
        include Ohm::DataTypes

        attribute :name
        attribute :questions, Type::Array

        collection :schedules, StandupSchedule, :standup

        def summary
          "#{name} (ID: #{id}) - #{questions.size} question(s)"
        end

        def description
          [
            "ID: #{id}",
            "Name: #{name}",
            "Questions:",
            questions.join("\n")
          ].join("\n")
        end

      end
    end
  end
end

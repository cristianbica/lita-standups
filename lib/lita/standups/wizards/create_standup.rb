require "active_support/core_ext/object/blank"

module Lita
  module Standups
    module Wizards
      class CreateStandup < Lita::Wizard

        step :name,
             label: 'Please give it a name:'

        step :questions,
             label: 'Enter the standup questions below:',
             multiline: true

        def finish_wizard
          Lita.logger.debug "Finishing wizard CreateStandup for user #{user_id}"
          @standup = Models::Standup.create(
            name: value_for(:name),
            questions: value_for(:questions).to_s.split("\n").map(&:strip).map(&:presence).compact
          )
          Lita.logger.debug "Created standup: #{@standup.summary}"
        end

        def final_message
          [
            "You're done! Below is the summary of your standup:",
            ">>>",
            @standup.description
          ].join("\n")
        end

      end
    end
  end
end

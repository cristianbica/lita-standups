module Lita
  module Wizards
    class CreateStandup < Lita::Wizard

      step :name,
           label: 'Please give it a name:'

      step :repeat,
           label: 'How often? (daily, weekly)',
           options: %w(daily weekly)

      step :day_of_week,
           label: 'What day of week? (monday ... sunday)',
           options: %w(monday tuesday wednesday thursday friday saturday sunday),
           if: ->(wizard) { value_for(:repeat) == 'weekly' }

      step :time,
           label: 'At what time? (ex 9am)',
           validate: /^([1-9]|1[0-2]|0[1-9])?(:[0-5][0-9])?\s?([aApP][mM])?$/

      step :questions,
           label: 'Enter the standup questions below (one message, one question per line): '

      step :channel,
           label: 'On what channel do you want to post the results to?'

      def finish_wizard
        Lita::Standup.create(
          id: id,
          name: value_for(:name),
          repeat: value_for(:repeat),
          day_of_week: value_for(:day_of_week),
          time: value_for(:time),
          questions: value_for(:questions),
          channel: value_for(:channel)
        )
      end

      def final_message
        [
          "You're done! Below is the summary of your standup:",
          ">>>",
          "ID: #{id}",
          "Name: #{value_for(:name)}",
          "Running #{value_for(:repeat)} " + (weekly? ? "on #{value_for(:day_of_week)} " : "") + "at #{value_for(:time)}",
          "Questions:",
          value_for(:questions),
          "Sending the result on #{value_for(:channel)}"
        ].join("\n")
      end

      def weekly?
        value_for(:day_of_week) == 'weekly'
      end

    end
  end
end

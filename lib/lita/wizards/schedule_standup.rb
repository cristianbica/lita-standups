module Lita
  module Wizards
    class ScheduleStandup < Lita::Wizard

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

      step :recipients,
           label: 'Enter the standup members (one message, separated by comma / space / new line): '

      step :channel,
           label: 'On what channel do you want to post the results to?'

      def finish_wizard
        Lita::Standups::Schedule.create(
          id: id,
          standup_id: standup.id,
          repeat: value_for(:repeat),
          day_of_week: value_for(:day_of_week),
          time: value_for(:time),
          recipients: value_for(:recipients),
          channel: value_for(:channel)
        )
      end

      def final_message
        [
          "You're done! Below is the summary of your scheduled standup:",
          ">>>",
          "ID: #{id}",
          "Standup: #{standup.name}",
          "Running #{value_for(:repeat)} " + (weekly? ? "on #{value_for(:day_of_week)} " : "") + "at #{value_for(:time)}",
          "Recipients:",
          value_for(:recipients),
          "Sending the result on #{value_for(:channel)}"
        ].join("\n")
      end

      def standup
        @standup ||= Lita::Standups::Standup.find(meta['standup_id'])
      end

      def weekly?
        value_for(:day_of_week) == 'weekly'
      end

    end
  end
end

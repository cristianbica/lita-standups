module Lita
  module Standups
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
             label: 'At what time? (ex 9am - time will be considered GMT time)',
             validate: /^([1-9]|1[0-2]|0[1-9])?(:[0-5][0-9])?\s?([aApP][mM])?$/

        step :recipients,
             label: 'Enter the standup members: ',
             multiline: true

        step :channel,
             label: 'On what channel do you want to post the results to?'

        def finish_wizard
          @schedule = Models::StandupSchedule.create(
            standup: standup,
            repeat: value_for(:repeat),
            day_of_week: value_for(:day_of_week),
            time: value_for(:time),
            recipients: value_for(:recipients).to_s.gsub("@", "").split(/[\s,\n]/m).map(&:strip).map(&:presence).compact,
            channel: value_for(:channel)
          )
          robot.schedule_standup(@schedule)
        end

        def final_message
          [
            "You're done! Below is the summary of your scheduled standup:",
            ">>>",
            @schedule.description
          ].join("\n")
        end

        def standup
          @standup ||= Models::Standup[meta['standup_id']]
        end

      end
    end
  end
end

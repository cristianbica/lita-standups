module Lita
  module Handlers
    class Standups < Handler

      route(/^debug standups$/, :debug_standups,
            command: true)

      route(/^list standups$/, :list_standups,
            command: true,
            help: { 'list standups' => 'list configured standups' })

      route(/^create standup$/, :create_standup,
            command: true,
            help: { 'create standup' => 'create a standup' })

      route(/^show standup (\w+)$/, :show_standup,
            command: true,
            help: { 'show standup STANDUP_ID' => 'shows details of a standup' })

      route(/^delete standup (\w+)$/, :delete_standup,
            command: true,
            help: { 'delete standup STANDUP_ID' => 'deletes a standup' })

      route(/^schedule standup (\w+)$/, :create_standups_schedule,
            command: true,
            help: { 'schedule standup STANDUP_ID' => 'schedule a standup' })

      route(/^unschedule standup (\w+)$/, :delete_standups_schedule,
            command: true,
            help: { 'unschedule standup SCHEDULE_ID' => 'unschedule a standup' })

      route(/^list standups schedules$/, :show_standups_schedule,
            command: true,
            help: { 'list standups schedules' => 'shows scheduled standups' })

      route(/^show standup schedule (\w+)$/, :show_standup_schedule,
            command: true,
            help: { 'show standup schedule SCHEDULE_ID' => 'shows a scheduled standup' })

      route(/^run standup (.+) with (.*)$/, :run_standup,
            command: true,
            help: { 'run standup STANDUP_ID with USERS' => 'runs a standup now (users space/comma separated)' })

      route(/^list standup sessions$/, :list_standup_sessions,
            command: true,
            help: { 'list standup sessions' => 'list all standups sessions' })

      route(/^show standup session (\w+)$/, :show_standup_session,
            command: true,
            help: { 'show standup session SESSION_ID' => 'show a standups session details' })

      def list_standups(request)
        standups = Models::Standup.all.to_a
        message = "Standups found: #{standups.size}."
        message << " Here they are: \n" if standups.size>0
        message << standups.map(&:summary).join("\n")
        request.reply message
      end

      def create_standup(request)
        start_wizard Wizards::CreateStandup, request.message
      end

      def show_standup(request)
        standup = Models::Standup[request.matches[0][0]]
        if standup
          request.reply "Here are the details of your standup: \n>>>\n#{standup.description}"
        else
          request.reply "I couldn't find a standup with ID=#{request.matches[0][0]}"
        end
      end

      def delete_standup(request)
        standup = Models::Standup[request.matches[0][0]]
        if standup
          standup.delete
          request.reply "Standup with ID #{standup.id} has been deleted"
        else
          request.reply "I couldn't find a standup with ID=#{request.matches[0][0]}"
        end
      end

      def create_standups_schedule(request)
        standup = Models::Standup[request.matches[0][0]]
        if standup
          start_wizard Wizards::ScheduleStandup, request.message, 'standup_id' => standup.id
        else
          request.reply "I couldn't find a standup with ID=#{request.matches[0][0]}"
        end
      end

      def show_standups_schedule(request)
        schedules = Models::StandupSchedule.all.to_a
        message = "Scheduled standups found: #{schedules.size}."
        message << " Here they are: \n" if schedules.size>0
        message << schedules.map(&:summary).join("\n")
        request.reply message
      end

      def delete_standups_schedule(request)
        schedule = Models::StandupSchedule[request.matches[0][0]]
        if schedule
          robot.unschedule_standup(schedule)
          schedule.delete
          request.reply "Schedule with ID #{schedule.id} has been deleted"
        else
          request.reply "I couldn't find a scheduled standup with ID=#{request.matches[0][0]}"
        end
      end

      def show_standup_schedule(request)
        schedule = Models::StandupSchedule[request.matches[0][0]]
        if schedule
          request.reply "Here are the details: \n>>>\n#{schedule.description}"
        else
          request.reply "I couldn't find a scheduled standup with ID=#{request.matches[0][0]}"
        end
      end

      def run_standup(request)
        standup = Models::Standup[request.matches[0][0]]
        recipients = request.matches[0][1].to_s.gsub("@", "").split(/[\s,\n]/m).map(&:strip).map(&:presence).compact
        if standup
          request.reply "I'll run the standup shortly and post the results here. Thanks"
          robot.run_standup standup.id, recipients, request.message.source.room
        else
          request.reply "I couldn't find a standup with ID=#{request.matches[0][0]}"
        end
      end

      def list_standup_sessions(request)
        sessions = Models::StandupSession.all.to_a
        message = "Sessions found: #{sessions.size}."
        message << " Here they are: \n" if sessions.size>0
        message << sessions.map(&:summary).join("\n")
        request.reply message
      end

      def show_standup_session(request)
        session = Models::StandupSession[request.matches[0][0]]
        if session
          message = "Here are the standup session details: \n #{session.description}\n"
          message << "\n*Responses:*\n"
          message << session.report_message
          request.reply message
        else
          request.reply "I couldn't find a standup session with ID=#{request.matches[0][0]}"
        end
      end

      def self.const_missing(name)
        Lita::Standups.const_defined?(name) ? Lita::Standups.const_get(name) : super
      end

      def debug_standups(request)
        request.reply "*Standups*"
        Models::Standup.all.each do |standup|
          request.reply ">>> \n" + standup.description
          request.reply "```\n#{standup.inspect}\n```"
        end

        request.reply "*Scheduled Standups*"
        Models::StandupSchedule.all.each do |schedule|
          request.reply ">>> \n" + schedule.description
          request.reply "```\n#{schedule.inspect}\n```"
        end

        request.reply "*Rufus Schedule*"
        request.reply robot.jobs_info.map{|j| "```\n" + j.join("\n") + "\n```" }.join("\n\n")

        request.reply "*Server time*: #{Time.now}"
      end

      Lita.register_handler(self)
    end
  end
end

require "active_support/core_ext/time"

module Lita
  module Standups
    class Manager

      DEFAULT_EXPIRATION_TIME = 3600

      def self.run(robot:, standup_id:, recipients:, room:)
        session = Models::StandupSession.create(
          standup_id: standup_id,
          recipients: recipients,
          room: room
        )
        new(robot: robot, session: session).run
      end

      def self.run_schedule(robot:, schedule_id:)
        Lita.logger.debug "Running scheduled standup for schedule ID=#{schedule_id}"
        schedule = Models::StandupSchedule[schedule_id]
        Lita.logger.debug "Found scheduled standup: #{schedule.inspect}"
        session = Lita::Standups::Models::StandupSession.create(
          standup: schedule.standup,
          standup_schedule: schedule,
          recipients: schedule.recipients,
          room: schedule.channel
        )
        Lita.logger.debug "Created session: #{session.inspect}"
        new(robot: robot, session: session).run
      rescue Exception => e
        Lita.logger.debug "Got exception while trying to run schedule ID #{schedule_id}"
        Lita.logger.debug e.inspect
        Lita.logger.debug e.backtrace.join("\n")
        raise e
      end

      def self.abort_expired_standups(robot:)
        Lita.logger.debug "Checking for expired standups"
        Lita::Standups::Models::StandupResponse.find(status: "pending").union(status: "running").each do |response|
          next unless Time.current - response.created_at > DEFAULT_EXPIRATION_TIME
          Lita.logger.debug "Found expired standup response: #{response.inspect}. Expiring ..."
          response.expired!
          response.save
          Lita::Wizard.cancel_wizard(response.user.id)
          target = Lita::Source.new(user: response.user, room: nil, private_message: true)
          robot.send_message target, "Expired. See you next time!"
        end
      end

      def self.complete_finished_standups(robot:)
        Lita.logger.debug "Checking for finished sesssions"
        Lita::Standups::Models::StandupSession.find(status: "completed", results_sent: "0").each do |session|
          Lita.logger.debug "Found finished session: #{session.inspect}. Posting results ..."
          new(robot: robot, session: session).post_results
        end
      end

      attr_accessor :robot, :session

      def initialize(robot:, session:)
        @robot = robot
        @session = session
      end

      def standup
        session.standup
      end

      def room
        @room ||= Lita::Source.new(user: nil, room: session.room)
      end

      def run
        Lita.logger.debug "Running standup for session ID=#{session.id}"
        session.running!
        session.save
        session.recipients.each { |recipient| ask_questions(recipient) }
      end

      def ask_questions(recipient)
        user = Lita::User.fuzzy_find(recipient)
        Lita.logger.debug "Running the wizard for recipient #{recipient} (#{user.inspect})"
        response = Models::StandupResponse.create(
          standup_session_id: session.id,
          user_id: user.id
        )
        dummy_source = Lita::Source.new(user: user, room: nil, private_message: true)
        dummy_message = Lita::Message.new(robot, '', dummy_source)
        begin
          Wizards::RunStandup.start robot, dummy_message, 'response_id' => response.id
        rescue Exception => e
          Lita.logger.debug "Got exception while trying to run the standup with #{recipient}"
          Lita.logger.debug e.inspect
          Lita.logger.debug e.backtrace.join("\n")
          response.aborted!
          response.save
        end
      end

      def post_results
        return if session.results_sent == "1"
        message = "The standup '#{standup.name}' has finished. Here's what everyone posted:\n\n#{session.report_message}"
        robot.send_message room, message
        session.results_sent = "1"
        session.save
      end

    end
  end
end

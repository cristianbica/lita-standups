module Lita
  module Standups
    class Manager

      EXPIRATION_TIME = 3600

      def self.run(robot:, standup_id:, recipients:, room:)
        session = Models::StandupSession.create(
          standup_id: standup_id,
          recipients: recipients,
          room: room
        )
        new(robot: robot, session: session).run
      end

      def self.run_schedule(robot:, schedule_id:)
        schedule = Models::StandupSchedule[schedule_id]
        session = Models::StandupSession.create(
          standup_id: schedule.standup_id,
          standup_schedule_id: schedule.id,
          recipients: schedule.recipients,
          room: schedule.channel
        )
        new(robot: robot, session: session).run
      end

      def self.abort_expired_standups(robot:)
        Lita::Standups::Models::StandupResponse.find(status: "pending").union(status: "running").each do |response|
          next unless Time.current - response.created_at > EXPIRATION_TIME
          response.expired!
          response.save
          Lita::Wizard.cancel_wizard(response.user.id)
          target = Lita::Source.new(user: response.user, room: nil, private_message: true)
          robot.send_message target, "Expired. See you next time!"
        end
      end

      def self.complete_finished_standups(robot:)
        Lita::Standups::Models::StandupSession.find(status: "completed", results_sent: false).each do |session|
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
        session.running!
        session.save
        session.recipients.each { |recipient| ask_questions(recipient) }
      end

      def ask_questions(recipient)
        user = Lita::User.fuzzy_find(recipient)
        response = Models::StandupResponse.create(
          standup_session_id: session.id,
          user_id: user.id
        )
        dummy_source = Lita::Source.new(user: user, room: nil, private_message: true)
        dummy_message = Lita::Message.new(robot, '', dummy_source)
        Wizards::RunStandup.start robot, dummy_message, 'response_id' => response.id
      end

      def post_results
        return if session.results_sent
        message = "The standup '#{standup.name}' has finished. Here's what everyone posted:\n\n#{session.report_message}"
        robot.send_message room, message
        session.results_sent = true
        session.save
      end

    end
  end
end

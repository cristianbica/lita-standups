module Lita
  module Standups
    class Manager

      def run(robot:, standup_id:, recipient:, room:)
        session = Models::StandupSession.create(
          standup_id: standup_id,
          recipient: recipient,
          room: room
        )
        new(robot: robot, session: session).run
      end

      def self.run_schedule(robot:, schedule_id:)
        schedule = Models::StandupSchedule[schedule_id]
        session = Models::StandupSession.create(
          standup_id: schedule.standup_id,
          schedule_id: schedule.id,
          recipient: schedule.recipient,
          room: schedule.channel
        )
        new(robot: robot, session: session).run
      end

      def self.send_reminders(robot:)

      end

      def self.abort_expired(robot:)

      end


      attr_accessor :robot, :session

      def initialize(robot:, session:)
        @robot = robot
        @session = robot
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

      def post_results(session)
        return if session.results_sent
        message = "The standup '#{standup.name}' has finished. Here's what everyone posted:\n#{session.report_message}"
        robot.send_message room, message
        session.results_sent = true
        session.save
      end

    end
  end
end

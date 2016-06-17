module Lita
  module Standups
    class StandupRunner

      def self.run_schedule(robot, schedule_id)
        schedule = Lita::Standups::Schedule.find(schedule_id)
        new(robot, schedule.standup_id, schedule_id, schedule.recipients, standup_id.channel).run
      end

      attr_accessor :robot, :standup, :schedule, :recipients, :room
      attr_reader :session

      def initialize(robot:, standup_id:, schedule_id: nil, recipients:, room:)
        @robot = robot
        @standup = Models::Standup[standup_id]
        @schedule = Models::StandupSchedule[schedule_id] unless schedule_id.nil?
        @recipients = recipients
        @room = Lita::Source.new(user: nil, room: room)
      end

      def run
        create_session
        session.running!
        recipients.each { |recipient| ask_questions(recipient) }
      end

      def create_session
        @session = Models::StandupSession.create(
          standup_id: standup.id,
          standup_schedule_id: schedule.try(:id),
          room: room.room
        )
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
        message = "The standup '#{standup.name}' has finished. Here's what everyone posted:\n#{session.report_message}"
        robot.send_message room, message
      end

    end
  end
end

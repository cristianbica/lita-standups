module Lita
  module Standups
    module Fixtures
      module_function

      def create_standups(count = 1)
        1.upto(count) do |i|
          create_standup(i)
        end
      end

      def create_standup(i = nil)
        Models::Standup.create(
          name: "standup-#{i || SecureRandom.hex(2)}",
          questions: 1.upto(3).map{|x| "Question #{x}" }
        )
      end

      def create_standup_schedules(count = 1)
        standups = Models::Standup.all.to_a.cycle
        1.upto(count) do |i|
          create_standup_schedule(standups.next)
        end
      end

      def create_standup_schedule(standup)
        Models::StandupSchedule.create(
          standup: standup,
          repeat: "daily",
          time: "9am",
          recipients: %w(user),
          channel: "#a"
        )
      end

      def create_standup_runs(count = 1)
        standups = Models::Standup.all.to_a.cycle
        1.upto(count) do |i|
          create_standup_run(standups.next)
        end
      end

      def create_standup_run(standup)
        session = Models::StandupSession.create(
          standup_id: standup.id,
          recipients: %w(1 2 3),
          room: "#a"
        )
        Models::StandupResponse.create(
          standup_session_id: session.id,
          user_id: 1,
          status: "completed",
          answers: %w(a1 a2 a3)
        )
        Models::StandupResponse.create(
          standup_session_id: session.id,
          user_id: 2,
          status: "completed",
          answers: %w(a1 a2 a3)
        )
        Models::StandupResponse.create(
          standup_session_id: session.id,
          user_id: 3,
          status: "expired"
        )
      end

      def cleanup_data
        Ohm.redis.call("keys", "Lita::Standups::Models*").each do |key|
          Ohm.redis.call("del", key)
        end
      end
    end
  end
end

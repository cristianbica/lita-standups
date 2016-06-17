module Lita
  module Standups
    module RobotMixin
      def initialize
        @scheduler = Rufus::Scheduler.new
        super
      end

      def scheduler
        @scheduler
      end

      def schedule_standups
        scheduler.jobs.each(&:unschedule)
        scheduler.cron '* * * * *' do |job|
          # TODO
        end
        # Lita::Standups::Schedule.all.each do |schedule|
        #   scheduler.cron standup.cron_line, tags: [:schedules, schedule.id], schedule_id: schedule.id do |job|
        #     StandupRunner.run_schedule(self, job.opts[:schedule_id])
        #   end
        # end
      end

      def run_standup(standup_id, recipients, room_id)
        scheduler.in "1s" do |job|
          Lita::Standups::StandupRunner.new(
            robot: self,
            standup_id: standup_id,
            recipients: recipients,
            room: room_id
          ).run
        end
      end

      def run
        schedule_standups
        super
      end
    end
  end

  class Robot
    prepend ::Lita::Standups::RobotMixin
  end

end

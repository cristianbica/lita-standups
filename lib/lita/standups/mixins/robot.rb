module Lita
  module Standups
    module Mixins
      module Robot
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
            Lita::Standups::Manager.send_reminders(robot: self)
            Lita::Standups::Manager.abort_expired(robot: self)
          end
          # Lita::Standups::Schedule.all.each do |schedule|
          #   scheduler.cron standup.cron_line, tags: [:schedules, schedule.id], schedule_id: schedule.id do |job|
          #     Lita::Standups::Manager.run_schedule(robot: self, schedule_id: job.opts[:schedule_id])
          #   end
          # end
        end

        def run_standup(standup_id, recipients, room_id)
          scheduler.in "1s" do |job|
            Lita::Standups::Manager.run(
              robot: self,
              standup_id: standup_id,
              recipients: recipients,
              room: room_id
            )
          end
        end

        def run
          schedule_standups
          super
        end
      end
    end
  end

  class Robot
    prepend ::Lita::Standups::Mixins::Robot
  end
end

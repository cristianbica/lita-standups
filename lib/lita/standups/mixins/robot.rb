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
            Lita::Standups::Manager.abort_expired_standups(robot: self)
            Lita::Standups::Manager.complete_finished_standups(robot: self)
          end
          Models::StandupSchedule.all.each do |standup_schedule|
            schedule_standup(standup_schedule)
          end
        end

        def schedule_standup(standup_schedule)
          scheduler.cron standup_schedule.cron_line, schedule_id: standup_schedule.id,
            tags: [:standup_schedules, "standup_schedule_#{standup_schedule.id}"] do |job|
            Lita::Standups::Manager.run_schedule(robot: self, schedule_id: job.opts[:schedule_id])
          end
        end

        def unschedule_standup(standup_schedule)
          scheduler.jobs(tags: [:standup_schedules, "standup_schedule_#{standup_schedule.id}"]).each(&:unschedule)
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

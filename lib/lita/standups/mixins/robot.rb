module Lita
  module Standups
    module Mixins
      module Robot
        def initialize(*args)
          @scheduler = Rufus::Scheduler.new if scheduler_enabled?
          super
        end

        # :nocov:
        def scheduler
          @scheduler
        end
        # :nocov:

        def scheduler_enabled?
          ENV['TEST'].nil?
        end

        def schedule_standups
          return unless scheduler_enabled?
          Lita.logger.debug "Scheduling standups"
          scheduler.jobs.each(&:unschedule)
          scheduler.cron '*/15 * * * * *', tags: [:standup_schedules, :abort_expired] do |job|
            Lita.logger.debug "Checking for expired standups"
            Lita::Standups::Manager.abort_expired_standups(robot: self)
          end
          scheduler.cron '*/15 * * * * *', tags: [:standup_schedules, :complete_finished] do |job|
            Lita.logger.debug "Checking for completed standups"
            Lita::Standups::Manager.complete_finished_standups(robot: self)
          end
          Models::StandupSchedule.all.each do |standup_schedule|
            schedule_standup(standup_schedule)
          end
        end

        def schedule_standup(standup_schedule)
          return unless scheduler_enabled?
          scheduler.cron standup_schedule.cron_line, schedule_id: standup_schedule.id,
            tags: [:standup_schedules, "standup_schedule_#{standup_schedule.id}"] do |job|
            Lita::Standups::Manager.run_schedule(robot: self, schedule_id: job.opts[:schedule_id])
          end
        end

        def unschedule_standup(standup_schedule)
          return unless scheduler_enabled?
          scheduler.jobs(tags: [:standup_schedules, "standup_schedule_#{standup_schedule.id}"]).each(&:unschedule)
        end

        def run_standup(standup_id, recipients, room_id)
          if scheduler_enabled?
            scheduler.in "5s", tags: [:standup_schedules, :run_standup] do |job|
              Lita::Standups::Manager.run(robot: self, standup_id: standup_id, recipients: recipients, room: room_id)
            end
          else
            Lita::Standups::Manager.run(robot: self, standup_id: standup_id, recipients: recipients, room: room_id)
          end
        end

        # :nocov:
        def run
          schedule_standups
          super
        end
        # :nocov:
      end
    end
  end

  class Robot
    prepend ::Lita::Standups::Mixins::Robot
  end
end

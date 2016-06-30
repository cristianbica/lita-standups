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
          Lita.logger.debug "Unscheduling any existing jobs"
          scheduler.jobs.each(&:unschedule)
          Lita.logger.debug "Scheduling standup status jobs"
          scheduler.cron '*/15 * * * * *', tags: [:standup_schedules, :abort_expired] do |job|
            Ohm.redis = Redic.new(Ohm.redis.url)
            Lita::Standups::Manager.abort_expired_standups(robot: self)
          end
          scheduler.cron '*/15 * * * * *', tags: [:standup_schedules, :complete_finished] do |job|
            Ohm.redis = Redic.new(Ohm.redis.url)
            Lita::Standups::Manager.complete_finished_standups(robot: self)
          end
          Lita.logger.debug "Scheduling standups"
          Models::StandupSchedule.all.each do |standup_schedule|
            schedule_standup(standup_schedule)
          end
        end

        def schedule_standup(standup_schedule)
          return unless scheduler_enabled?
          scheduler.cron standup_schedule.cron_line, schedule_id: standup_schedule.id,
            tags: [:standup_schedules, "standup_schedule_#{standup_schedule.id}"] do |job|
              Ohm.redis = Redic.new(Ohm.redis.url)
              Lita.logger.debug "Calling run_schedule on Manager for #{job.opts[:schedule_id]}"
              Lita::Standups::Manager.run_schedule(robot: self, schedule_id: job.opts[:schedule_id])
          end
        end

        def unschedule_standup(standup_schedule)
          return unless scheduler_enabled?
          Lita.logger.debug "Unscheduling standup scheduled #{standup_schedule.id}"
          scheduler.jobs(tags: [:standup_schedules, "standup_schedule_#{standup_schedule.id}"]).each(&:unschedule)
        end

        def run_standup(standup_id, recipients, room_id)
          if scheduler_enabled?
            scheduler.in "5s", tags: [:standup_schedules, :run_standup] do |job|
              Ohm.redis = Redic.new(Ohm.redis.url)
              Lita.logger.debug "Calling run on Manager for standup #{standup_id} (recipients: #{recipients.join(", ")}"
              Lita::Standups::Manager.run(robot: self, standup_id: standup_id, recipients: recipients, room: room_id)
            end
          else
            Lita.logger.debug "Calling run on Manager for standup #{standup_id} (recipients: #{recipients.join(", ")}"
            Lita::Standups::Manager.run(robot: self, standup_id: standup_id, recipients: recipients, room: room_id)
          end
        end

        def jobs_info
          scheduler.jobs.map do |job|
            [
              "Type: #{job.class}",
              "ID: #{job.job_id}",
              "Tags: #{job.tags.join(', ')}",
              ("Options: #{job.opts.except(:tags).inspect}" if job.opts.except(:tags).size > 0),
              "Next Run: #{job.next_time} (#{job.next_time - Time.now} seconds from now)",
              "Schedule: #{job.try(:original)}"
            ].compact
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

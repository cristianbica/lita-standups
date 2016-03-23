module Lita
  module_function

  def scheduler
    @scheduler ||= Rufus::Scheduler.new
  end

  def setup_scheduler
    Lita::Standup.all.each do |standup|
      scheduler.cron standup.cron_line, tags: [:standups, standup.id], standup_id: standup.id do |job|
        Lita::Standup.find(job.opts[:standup_id]).run
      end
    end
  end
end

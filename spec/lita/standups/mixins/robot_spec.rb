require "spec_helper"

describe "Robot Mixin" do
  include Lita::Standups::Fixtures

  let(:robot) { Lita::Robot.new }

  before do
    create_standups(3)
    create_standup_schedules(3)
  end

  after do
    cleanup_data
  end

  context "with scheduling disabled" do
    let(:scheduler) { double }
    let(:job) { double }

    before do
      allow(robot).to receive(:scheduler).and_return(scheduler)
      allow(robot).to receive(:scheduler_enabled?).and_return(false)
    end

    it "shouldn't try to schedule standups" do
      expect(scheduler).to receive(:jobs).never
      robot.schedule_standups
    end

    it "shouldn't try to schedule a standup" do
      expect(scheduler).to receive(:cron).never
      robot.schedule_standup("dummy")
    end

    it "shouldn't try to unschedule a standup" do
      expect(scheduler).to receive(:cron).never
      robot.unschedule_standup("dummy")
    end

    it "should try to run a standup inline" do
      expect(scheduler).to receive(:in).never
      expect(Lita::Standups::Manager).to receive(:run).once
      robot.run_standup("standup_id", "recipients", "room_id")
    end
  end

  context "with scheduling enabled" do
    let(:scheduler) { double }
    let(:job) { double }

    before do
      allow(robot).to receive(:scheduler).and_return(scheduler)
      allow(robot).to receive(:scheduler_enabled?).and_return(true)
    end

    it "should try to schedule standups" do
      expect(scheduler).to receive(:jobs).once.and_return([])
      expect(scheduler).to receive(:cron).twice
      expect(robot).to receive(:schedule_standup).exactly(3).times
      robot.schedule_standups
    end

    it "should try to schedule a standup" do
      expect(scheduler).to receive(:cron).once
      robot.schedule_standup(Lita::Standups::Models::StandupSchedule[1])
    end

    it "shoul try to unschedule a standup" do
      expect(job).to receive(:unschedule).once
      expect(scheduler).to receive(:jobs).and_return([job])
      robot.unschedule_standup(Lita::Standups::Models::StandupSchedule[1])
    end

    it "should try to run a standup in the scheduler" do
      expect(scheduler).to receive(:in).once
      expect(Lita::Standups::Manager).to receive(:run).never
      robot.run_standup("standup_id", "recipients", "room_id")
    end
  end

  context "running jobs" do
    let(:scheduler) { Rufus::Scheduler.new }

    before do
      allow(robot).to receive(:scheduler).and_return(scheduler)
      allow(robot).to receive(:scheduler_enabled?).and_return(true)
    end

    it "should call abort_expired_standups on the manager when the abort_expired job runs" do
      robot.schedule_standups
      expect(Lita::Standups::Manager).to receive(:abort_expired_standups)
      scheduler.jobs(tags: [:abort_expired]).first.call
    end

    it "should call complete_finished_standups on the manager when the complete_finished job runs" do
      robot.schedule_standups
      expect(Lita::Standups::Manager).to receive(:complete_finished_standups)
      scheduler.jobs(tags: [:complete_finished]).first.call
    end

    it "should run a standup inside the scheduler" do
      robot.run_standup("standup_id", "recipients", "room_id")
      expect(Lita::Standups::Manager).to receive(:run)
      scheduler.jobs(tags: [:run_standup]).first.call
    end

    it "should call run on the manager when a scheduled standup job is called" do
      robot.schedule_standup(Lita::Standups::Models::StandupSchedule[1])
      expect(Lita::Standups::Manager).to receive(:run_schedule)
      scheduler.jobs(tags: [:standup_schedules, :standup_schedule_1]).first.call
    end
  end

end

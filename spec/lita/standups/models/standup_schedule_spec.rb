require "spec_helper"

describe Lita::Standups::Models::StandupSchedule do
  include Lita::Standups::Fixtures

  before do
    create_standups(1)
    create_standup_schedules(1)
  end

  after do
    cleanup_data
  end

  subject { described_class[1] }

  it "should generate a cron line for a daily schedule" do
    expect(subject.cron_line).to eq("0 9 * * * UTC")
  end

  it "should generate a cron line for a weekly schedule" do
    subject.repeat = "weekly"
    subject.day_of_week = "tuesday"
    expect(subject.cron_line).to eq("0 9 * * 2 UTC")
  end

  it "should generate a cron line for a workdays schedule" do
    subject.repeat = "workdays"
    expect(subject.cron_line).to eq("0 9 * * 1,2,3,4,5 UTC")
  end

end

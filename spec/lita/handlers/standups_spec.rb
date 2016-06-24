require "spec_helper"

describe Lita::Handlers::Standups, lita_handler: true do

  it { is_expected.to route_command("list standups").to(:list_standups) }
  it { is_expected.to route_command("create standup").to(:create_standup) }
  it { is_expected.to route_command("show standup 42").to(:show_standup) }
  it { is_expected.to route_command("delete standup 42").to(:delete_standup) }
  it { is_expected.to route_command("schedule standup 42").to(:create_standups_schedule) }
  it { is_expected.to route_command("unschedule standup 42").to(:delete_standups_schedule) }
  it { is_expected.to route_command("list standups schedules").to(:show_standups_schedule) }
  it { is_expected.to route_command("show standup schedule 42").to(:show_standup_schedule) }
  it { is_expected.to route_command("run standup 42 with x,y").to(:run_standup) }
  it { is_expected.to route_command("list standup sessions").to(:list_standup_sessions) }
  it { is_expected.to route_command("show standup session 42").to(:show_standup_session) }

end

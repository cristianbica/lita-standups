require "spec_helper"

describe Lita::Handlers::Standups, lita_handler: true, additional_lita_handlers: Lita::Handlers::Wizard do
  include Lita::Standups::Fixtures

  before do
    Lita::User.create(2, name: "User2")
    Lita::User.create(3, name: "User3")
    create_standups(3)
    create_standup_schedules(3)
    create_standup_runs(3)
    robot.registry.register_hook(:validate_route, Lita::Extensions::Wizard)
  end

  after do
    cleanup_data
  end

  context "managing standups" do

    it "should list standups" do
      send_command("list standups")
      expect(replies.last).to match(/found: 3/)
      expect(replies.last).to match(/ID: 1/)
    end

    it "should start the create standup wizard" do
      expect_any_instance_of(described_class).to \
        receive(:start_wizard).with(Lita::Standups::Wizards::CreateStandup, anything)
      send_command("create standup")
    end

    it "should create a standup" do
      expect do
        send_command("create standup")
        send_message("test-name", privately: true)
        send_message("q1", privately: true)
        send_message("q2", privately: true)
        send_message("done", privately: true)
      end.to change { Lita::Standups::Models::Standup.all.count }.by(1)
    end

    it "should show the details of a standup" do
      send_command("show standup 1")
      expect(replies.last).to match(/ID: 1/)
      expect(replies.last).to match(/Name:/)
    end

    it "should show an error message when trying to get the details of an inexisting standup" do
      send_command("show standup 100")
      expect(replies.last).to match(/I couldn't find a standup/)
    end

    it "should delete a standup" do
      expect do
        send_command("delete standup 1")
      end.to change { Lita::Standups::Models::Standup.all.count }.by(-1)
      expect(replies.last).to match(/Standup with ID 1 has been deleted/)
    end

    it "should show an error message when trying to delete an inexisting standup" do
      expect do
        send_command("delete standup 100")
      end.not_to change { Lita::Standups::Models::Standup.all.count }
      expect(replies.last).to match(/I couldn't find a standup/)
    end
  end

  context "managing standups schedules" do
    it "should start the wizard when trying to schedule a standup" do
      expect_any_instance_of(described_class).to \
        receive(:start_wizard).with(Lita::Standups::Wizards::ScheduleStandup, anything, { "standup_id" => "1" })
      send_command("schedule standup 1")
    end

    it "should show an error message when trying to schedule an inexisting standup" do
      expect do
        send_command("schedule standup 100")
      end.not_to change { Lita::Standups::Models::StandupSchedule.all.count }
      expect(replies.last).to match(/I couldn't find a standup/)
    end

    it "should schedule a daily standup" do
      expect do
        send_command("schedule standup 1")
        send_message("daily", privately: true)
        send_message("12:42pm", privately: true)
        send_message("user", privately: true)
        send_message("done", privately: true)
        send_message("#a", privately: true)
      end.to change { Lita::Standups::Models::StandupSchedule.all.count }.by(1)
      expect(replies.last).to match(/You're done!/)
    end

    it "should schedule a weekly standup" do
      expect do
        send_command("schedule standup 1")
        send_message("weekly", privately: true)
        send_message("tuesday", privately: true)
        send_message("12:42pm", privately: true)
        send_message("user", privately: true)
        send_message("done", privately: true)
        send_message("#a", privately: true)
      end.to change { Lita::Standups::Models::StandupSchedule.all.count }.by(1)
      expect(replies.last).to match(/You're done!/)
    end

    it "should delete a standup schedule" do
      expect do
        send_command("unschedule standup 1")
      end.to change { Lita::Standups::Models::StandupSchedule.all.count }.by(-1)
      expect(replies.last).to match(/Schedule with ID 1 has been deleted/)
    end

    it "should show an error message when trying to delete an inexisting standup schedule" do
      expect do
        send_command("unschedule standup 100")
      end.not_to change { Lita::Standups::Models::StandupSchedule.all.count }
      expect(replies.last).to match(/I couldn't find a scheduled standup/)
    end

    it "should list all standup schedules" do
      send_command("list standups schedules")
      expect(replies.last).to match(/Scheduled standups found: 3/)
    end

    it "should show details of a standup schedule" do
      send_command("show standup schedule 1")
      expect(replies.last).to match(/Here are the details/)
      expect(replies.last).to match(/ID: 1/)
    end

    it "should show an error message when trying to get the details of an inexisting standup schedule" do
      send_command("show standup schedule 100")
      expect(replies.last).to match(/I couldn't find a scheduled standup/)
    end
  end

  context "running standups" do
    it "should ask the robot to run a standup" do
      expect(robot).to receive(:run_standup).with("1", %w(user), anything)
      send_command("run standup 1 with user")
    end

    it "should show an error message when trying to run an inexisting standup schedule" do
      send_command("run standup 100 with user")
      expect(replies.last).to match(/I couldn't find a standup/)
    end

    it "should run a standup" do
      expect do
        send_command("run standup 1 with 1")
        send_message("a1", privately: true)
        send_message("done", privately: true)
        send_message("a2", privately: true)
        send_message("done", privately: true)
        send_message("a3", privately: true)
        send_message("done", privately: true)
      end.to change { Lita::Standups::Models::StandupSession.all.count }.by(1)
    end

    it "should be able to abort a running standup" do
      send_command("run standup 1 with 1")
      send_message("a1", privately: true)
      send_message("done", privately: true)
      send_message("abort", privately: true)
      expect(replies.last).to match(/Aborting/)
    end

    it "should list all standup sessions" do
      send_command("list standup sessions")
      expect(replies.last).to match(/Sessions found: 3. Here they are/)
    end

    it "should show the details of a standup sessions" do
      send_command("show standup session 1")
      expect(replies.last).to match(/Here are the standup session details/)
      expect(replies.last).to match(/ID: 1/)
    end

    it "should show an error message when trying to show an inexisting standup session" do
      send_command("show standup session 100")
      expect(replies.last).to match(/I couldn't find a standup session/)
    end


  end



end

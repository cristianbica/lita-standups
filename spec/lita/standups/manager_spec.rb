require "spec_helper"

describe Lita::Standups::Manager do
  include Lita::Standups::Fixtures

  let(:robot) { Lita::Robot.new }

  before do
    Lita::User.create(2, name: "User2")
    Lita::User.create(3, name: "User3")
    create_standups(3)
    create_standup_schedules(3)
    create_standup_runs(2)
  end

  after do
    cleanup_data
  end

  context "class methods" do
    it "should create a session and call run on a new manager instance when running a standup" do
      expect_any_instance_of(described_class).to receive(:run)
      expect do
        described_class.run(robot: robot, standup_id: "1", recipients: %w(user1), room: "#a")
      end.to change { Lita::Standups::Models::StandupSession.all.count }.by(1)
    end

    it "should create a session and call run on a new manager instance when running a standup schedule" do
      expect_any_instance_of(described_class).to receive(:run)
      expect do
        described_class.run_schedule(robot: robot, schedule_id: "1")
      end.to change { Lita::Standups::Models::StandupSession.all.count }.by(1)
    end

    it "should mark expired reponses as expired" do
      responses = [Lita::Standups::Models::StandupResponse[1], Lita::Standups::Models::StandupResponse[2]]
      responses[0].created_at = Time.now - 100_000
      allow(Lita::Standups::Models::StandupResponse).to receive_message_chain(:find, :union).and_return(responses)
      expect(responses[0]).to receive(:expired!)
      expect(responses[0]).to receive(:save)
      expect(Lita::Wizard).to receive(:cancel_wizard)
      expect(robot).to receive(:send_message)
      described_class.abort_expired_standups(robot: robot)
    end

    it "should post results on completed sessions" do
      allow(Lita::Standups::Models::StandupSession).to receive(:find).and_return(["dummy"])
      expect_any_instance_of(described_class).to receive(:post_results)
      described_class.complete_finished_standups(robot: robot)
    end
  end

  context "instance methods" do
    context "running a session" do
      it "should create a responses for each user" do
        allow(Lita::Standups::Wizards::RunStandup).to receive(:start)
        expect do
          described_class.run(robot: robot, standup_id: "1", recipients: %w(1 2), room: "#a")
        end.to change { Lita::Standups::Models::StandupResponse.all.count }.by(2)
      end

      it "should start the run wizard" do
        expect(Lita::Standups::Wizards::RunStandup).to receive(:start)
        described_class.run(robot: robot, standup_id: "1", recipients: %w(1), room: "#a")
      end
    end

    context "posting results" do
      it "should send a message" do
        session = Lita::Standups::Models::StandupSession[1]
        expect(robot).to receive(:send_message)
        described_class.new(robot: robot, session: session).post_results
      end

      it "should set the results_sent flag on the session" do
        session = Lita::Standups::Models::StandupSession[1]
        allow(robot).to receive(:send_message)
        expect do
          described_class.new(robot: robot, session: session).post_results
        end.to change { Lita::Standups::Models::StandupSession[1].results_sent }.to(true)
      end

      it "sholdn't post anything if already posted" do
        session = Lita::Standups::Models::StandupSession[1]
        session.results_sent = true
        session.save
        expect(robot).to receive(:send_message).never
        described_class.new(robot: robot, session: session).post_results
      end
    end
  end
end

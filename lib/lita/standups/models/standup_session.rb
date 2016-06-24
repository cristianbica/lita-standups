module Lita
  module Standups
    module Models
      class StandupSession < Ohm::Model

        include Ohm::Callbacks
        include Ohm::Timestamps
        include Ohm::DataTypes

        attribute :status
        attribute :room
        attribute :counts, Type::Hash
        attribute :recipients, Type::Array
        attribute :results_sent, Type::Boolean

        reference :standup, Standup
        reference :standup_schedule, StandupSchedule
        collection :standup_responses, StandupResponse, :standup_session

        index :status
        index :results_sent

        def before_create
          self.status = 'pending'
          self.results_sent = false
        end

        %w(pending running completed).each do |status_name|
          define_method("#{status_name}!") do
            self.status = status_name
          end
        end

        def update_status
          self.counts = { 'total' => 0, 'finished' => 0 }
          standup_responses.each do |r|
            counts[r.status] = counts[r.status].to_i + 1
            counts['total'] = counts['total'] + 1
            counts['finished'] = counts['finished'] + 1 if r.finished?
          end
          completed! if counts['total'] == counts['finished']
          save
        end

        def report_message
          standup_responses.map(&:report_message).join("\n")
        end

        def summary
          "ID: #{id} - standup #{standup.name} ran on #{created_at.strftime('%c')}"
        end

        def description
          messages = ["ID: #{id}"]
          messages << "Standup: #{standup.name}"
          messages << "Date: #{created_at.strftime('%c')}"
          messages << "Total recipients: #{counts['total']}"
          messages << "Total finished: #{counts['finished']}"
          messages.join("\n")
        end
      end
    end
  end
end

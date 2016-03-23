module Lita
  module Handlers
    class Standups < Handler

      route(/^standups list$/, :list_standups,
            command: true,
            help: { 'standups list' => 'list configured standups' })

      route(/^standups create$/, :create_standup,
            command: true,
            help: { 'standups create' => 'create a standup' })

      route(/^standups show (.+)$/, :show_standup,
            command: true,
            help: { 'standups show ID' => 'shows details of a standup' })

      route(/^standups delete (.+)$/, :delete_standup,
            command: true,
            help: { 'standups delete ID' => 'deletes a standup' })

      route(/^standups run (.+) with (.+)$/, :run_standup,
            command: true,
            help: { 'standups run ID with USERS' => 'runs a standup now for a number of users (space separated)' })

      on :loaded, :setup_scheduler

      def list_standups(request)
        standups = Lita::Standup.all
        message = "Standups found: #{standups.size}."
        message << " Here they are: \n" if standups.size>0
        message << standups.map(&:summary).join("\n")
        request.reply message
      end

      def create_standup(request)
        Lita::Wizards::CreateStandup.start request.message
      end

      def show_standup(request)
        standup = Lita::Standup.find(request.args[1])
        if standup
          request.reply "Here are the details of your standup: \n>>>\n#{standup.description}"
        else
          request.reply "I couldn't find a standup with ID=#{request.args[1]}"
        end
      end

      def delete_standup(request)
        standup = Lita::Standup.find(request.args[1])
        if standup
          standup.delete
          request.reply "Standup with ID #{standup.id} has been deleted"
        else
          request.reply "I couldn't find a standup with ID=#{request.args[1]}"
        end
      end

      def run_standup(request)
        standup = Lita::Standup.find(request.args[1])
        if standup
          standup.run request.args[2]
          request.reply "I'll run the standup shortly. I'll post the results on #{standup.channel}. Thanks"
        else
          request.reply "I couldn't find a standup with ID=#{request.args[1]}"
        end
      end

      def setup_scheduler(_payload)
        Lita.setup_scheduler
      end

      Lita.register_handler(self)
    end
  end
end

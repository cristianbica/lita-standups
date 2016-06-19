module Lita
  module Standups
    module Wizards
      class RunStandup < Lita::Wizard

        def response
          @response ||= Models::StandupResponse[meta['response_id']]
        end

        def session
          response.standup_session
        end

        def standup
          session.standup
        end

        def steps
          @steps ||= standup.questions.map.with_index(1) do |question, index|
            OpenStruct.new(
              name: "q#{index}",
              label: question,
              multiline: true
            )
          end
        end

        def start_wizard
          response.running!
          response.save
        end

        def abort_wizard
          response.aborted!
          response.save
        end

        def finish_wizard
          response.completed!
          response.answers = values
          response.save
          if session.completed?
            robot = message.instance_variable_get(:"@robot")
            Lita::Standups::Manager.post_results(robot: robot, session: session)
          end
        end

        def initial_message
          "Hey. I'm running the '#{standup.name}' standup. Please answer the following questions."
        end

        def final_message
          "You're done. Thanks"
        end

      end
    end
  end
end

module Lita
  module Standups
    module Models
      extend ActiveSupport::Autoload

      autoload :Standup
      autoload :StandupResponse
      autoload :StandupSchedule
      autoload :StandupSession
    end
  end
end

module Lita
  module Standups
    module Wizards
      extend ActiveSupport::Autoload

      autoload :CreateStandup
      autoload :RunStandup
      autoload :ScheduleStandup
    end
  end
end

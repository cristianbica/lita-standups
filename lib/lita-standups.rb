require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

module Lita
  module Standups
  end
end

require "lita-wizard"
require "rufus-scheduler"
require "ohm"
require "ohm/contrib"
require "active_support"

require "lita/handlers/standups"
require "lita/standups/wizards"
require "lita/standups/models"
require "lita/standups/manager"
require "lita/standups/mixins/robot"

Lita::Handlers::Standups.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)

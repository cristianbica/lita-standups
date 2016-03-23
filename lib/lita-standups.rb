require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita-wizard"
require "rufus-scheduler"
require "lita/handlers/standups"
require "lita/wizards/create_standup"
require "lita/standup"
require "lita/scheduler"

Lita::Handlers::Standups.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)

module Lita
  module Standups
    module Models
      class Base < Ohm::Model

        include Ohm::Callbacks
        include Ohm::Timestamps
        include Ohm::DataTypes

        def self.redis
          Ohm.redis
        end

      end
    end
  end
end


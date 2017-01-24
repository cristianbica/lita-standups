module Lita
  module Standups
    module Models
      class Base < Ohm::Model

        include Ohm::Callbacks
        include Ohm::Timestamps
        include Ohm::DataTypes

        def self.redis
          # Password in the URL must only use URL safe characters
          # This appears to be a bug in Ohm or Redic. 
          @redic_url = ENV['REDIS_URL'] || 'redis://127.0.0.1:6379'
          Ohm.redis = Redic.new(@redic_url)
        end

      end
    end
  end
end


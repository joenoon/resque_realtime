class Resque::Realtime
  extend Resque::RealtimeHelpers
  
  class << self
  
    def redis=(server)
      @@redis = server
    end

    def redis
      @@redis || raise("!!! Set Resque::Realtime.redis")
    end
    
  end

end

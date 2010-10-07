class Resque::Realtime::Disconnected < Resque::Realtime
  @queue = :realtime
  
  class << self

    # Track user being disconnected
  
    def perform(server_env, conn_id)
      disconnect!(server_env.stringify_keys, conn_id)
    end
    
  end

end

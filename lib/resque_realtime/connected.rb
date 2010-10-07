class Resque::Realtime::Connected < Resque::Realtime
  @queue = :realtime
  
  class << self

    # Track user being connected
  
    def perform(server_env, conn_id)
      connect!(server_env.stringify_keys, conn_id)
    end
    
  end

end

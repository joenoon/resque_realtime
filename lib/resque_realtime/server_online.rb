class Resque::Realtime::ServerOnline < Resque::Realtime
  @queue = :realtime
  
  class << self

    # Track new node server
  
    def perform(server_env)
      server_online!(server_env.stringify_keys)
    end
    
  end

end

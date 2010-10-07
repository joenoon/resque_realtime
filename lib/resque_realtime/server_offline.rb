class Resque::Realtime::ServerOffline < Resque::Realtime
  @queue = :realtime
  
  class << self

    # Track offline node server
  
    def perform(server_env)
      server_offline!(server_env.stringify_keys)
    end
    
  end

end

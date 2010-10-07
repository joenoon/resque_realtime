class Resque::Realtime
  extend Resque::RealtimeHelpers
  
  class << self
  
    def redis=(server)
      @@redis = server
    end
    
    def redis
      @@redis || raise("!!! Set Resque::Realtime.redis")
    end
    
    def callbacks
      @@callbacks ||= {}
    end

    def add_callback(type, &block)
      @@callbacks ||= {}
      @@callbacks[type] ||= []
      @@callbacks[type].push(block)
      @@callbacks[type].size - 1 # return index
    end
    
    def clear_callback(type, index)
      @@callbacks ||= {}
      @@callbacks[type] ||= []
      @@callbacks[type][index] = nil
    end

    def clear_callbacks(type)
      @@callbacks ||= {}
      @@callbacks[type] = []
    end
    
    def run_callbacks(type, *args)
      cbs = callbacks[type]
      return unless cbs
      cbs.each do |cb|
        if cb && cb.call(*args) == false
          break
        end
      end
    end
    
  end

end

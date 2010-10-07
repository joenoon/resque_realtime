require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'resque_realtime'

class Test::Unit::TestCase
  
  def redis
    @redis ||= begin
      
      host = ENV["TEST_REDIS_HOST"] || "127.0.0.1"
      port = ENV["TEST_REDIS_PORT"] || 6379
      db   = ENV["TEST_REDIS_DB"]
      
      if !db || db == ""
        raise "Set TEST_REDIS_HOST, TEST_REDIS_PORT, and TEST_REDIS_DB environment variables.  Be careful, this DB will be flushed!!!"
      end
      
      r = Redis.new(:host => host, :port => 6379, :db => db)
      Resque.redis = r
      Resque::Realtime.redis = r
      r

    end
  end

  def poprand
    @randids ||= (10000..20000).to_a.sort_by { rand }
    @randids.pop
  end
  
  def connect_new(server_env)
    add_resource_for_user(server_env, poprand)
  end
  
  def add_resource_for_user(server_env, user_id)
    session_id = poprand
    Resque::Realtime::Connected.perform(server_env, "#{user_id}:#{session_id}")
    { :user_id => user_id, :session_id => session_id }.merge(server_env)
  end
  
  def disconnect_resource(opts)
    Resque::Realtime::Disconnected.perform(opts, "#{opts[:user_id]}:#{opts[:session_id]}")
  end
  
  def server_offline(server_env)
    Resque::Realtime::ServerOffline.perform(server_env)
  end
  
  # lookups
  
  def resources_for_user(user_id)
    Resque::Realtime.redis.scard Resque::Realtime.user_resources_key(user_id)
  end
  
  def connected_users_count
    Resque::Realtime.redis.scard Resque::Realtime.connected_users_key
  end
  
  def connected_resources_count
    Resque::Realtime.redis.scard Resque::Realtime.connected_resources_key
  end

  def server_connected_users_count(server_env)
    Resque::Realtime.redis.scard Resque::Realtime.server_connected_users_key(server_env)
  end
  
  def server_connected_resources_count(server_env)
    Resque::Realtime.redis.scard Resque::Realtime.server_connected_resources_key(server_env)
  end
  
  def servers_count
    Resque::Realtime.redis.scard Resque::Realtime.servers_key
  end
  
end

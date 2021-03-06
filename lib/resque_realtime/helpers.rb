require 'digest/sha1'
module Resque::RealtimeHelpers
  extend self
  
  def dummy_keys
    [ "rt:dummy:key" ]
  end

  def random_safe_key
    str = "#{[Array.new(40){rand(256).chr}.join].pack("m")[0...40]}-#{Time.now.to_f}"
    sha = Digest::SHA1.hexdigest(str)
    "rt:rand:#{Process.pid}:#{sha}"
  end

  def user_resources_key(user_id)
    "rt:user:#{user_id}:resources"
  end

  def connected_users_key
    "rt:connected_users"
  end

  def connected_resources_key
    "rt:connected_resources"
  end

  def server_connected_users_key(server_env)
    "rt:server:#{server_id(server_env)}:connected_users"
  end

  def server_connected_resources_key(server_env)
    "rt:server:#{server_id(server_env)}:connected_resources"
  end

  def servers_key
    "rt:servers"
  end

  def server_id(server_env)
    server_env = server_env.stringify_keys
    "#{server_env["public_addr"]}:#{server_env["port"]}"
  end

  def extract_user_id(resource)
    resource.split(":").first
  end

  def server_id_to_server_env(server_id)
    parts = server_id.split(":")
    { "public_addr" => parts[0], "port" => parts[1] }
  end

  def resources_for_user(user_id)
    redis.smembers user_resources_key(user_id)
  end

  def connect!(server_env, resource)
    ensure_server_in_servers_key!(server_env)
    user_id = extract_user_id(resource)
    redis.sadd(user_resources_key(user_id), resource)
    if redis.sadd(server_connected_resources_key(server_env), resource)
      run_callbacks(:resource_connected, server_env, resource)
    end
    redis.sadd(server_connected_users_key(server_env), user_id)
    sync_globals!
  end

  def disconnect!(server_env, resource)
    user_id = extract_user_id(resource)
    redis.srem(user_resources_key(user_id), resource)
    if redis.srem(server_connected_resources_key(server_env), resource)
      run_callbacks(:resource_disconnected, server_env, resource)
    end
    if redis.sinter(user_resources_key(user_id), server_connected_resources_key(server_env)).size.zero?
      redis.srem(server_connected_users_key(server_env), user_id)
    end
    sync_globals!
  end

  def sync_globals!
    server_envs = redis.smembers(servers_key).map { |server_id| server_id_to_server_env(server_id) }
  
    server_resource_keys = server_envs.map { |server_env| server_connected_resources_key(server_env) } + dummy_keys
    redis.sunionstore(connected_resources_key, *server_resource_keys)
  
    server_user_keys = server_envs.map { |server_env| server_connected_users_key(server_env) } + dummy_keys
    redis.sunionstore(connected_users_key, *server_user_keys)
  end
  
  def disconnect_all!(server_env)
    redis.smembers(server_connected_resources_key(server_env)).each do |resource|
      disconnect!(server_env, resource)
    end
  end
  
  def ensure_server_in_servers_key!(server_env)
    redis.sadd(servers_key, server_id(server_env))
  end

  def server_online!(server_env)
    disconnect_all!(server_env)
    ensure_server_in_servers_key!(server_env)
  end

  def server_offline!(server_env)
    disconnect_all!(server_env)
    redis.srem(servers_key, server_id(server_env))
  end
  
  def dispatch_to_resources(resources, payload)
    temp_key = random_safe_key
    redis.del temp_key
    resources.each do |resource|
      redis.sadd temp_key, resource
    end
    redis.smembers(servers_key).each do |server_id|
      server_env = server_id_to_server_env(server_id)
      server_resources_key = server_connected_resources_key(server_env)
      matching_resources = redis.sinter(temp_key, server_resources_key)
      if matching_resources.any?
        run_callbacks(:dispatch_to_resources, server_env, matching_resources, payload)
      end
    end
    redis.del temp_key
  end

end

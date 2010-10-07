require 'helper'

class TestResqueRealtime < Test::Unit::TestCase
  
  context "Resque Realtime" do

    setup do
      redis.flushdb
    end

    should "should maintain correct users" do

      server_env = { :public_addr => "127.0.0.1", :port => 2000 }

      assert_equal 0, connected_users_count
      assert_equal 0, connected_resources_count
      assert_equal 0, server_connected_users_count(server_env)
      assert_equal 0, server_connected_resources_count(server_env)

      bob1 = connect_new(server_env)
      joe1 = connect_new(server_env)
      jim1 = connect_new(server_env)
      sam1 = connect_new(server_env)

      # check each user has 1 open resource
      [ bob1, joe1, jim1, sam1 ].each do |c|
        assert_equal 1, resources_for_user(c[:user_id])
      end

      # add 1 resource to joe
      joe2 = add_resource_for_user(server_env, joe1[:user_id])

      assert_equal 2, resources_for_user(joe1[:user_id])

      # add 5 resources to bob
      bob2 = add_resource_for_user(server_env, bob1[:user_id])
      bob3 = add_resource_for_user(server_env, bob1[:user_id])
      bob4 = add_resource_for_user(server_env, bob1[:user_id])
      bob5 = add_resource_for_user(server_env, bob1[:user_id])
      bob6 = add_resource_for_user(server_env, bob1[:user_id])

      assert_equal 4, connected_users_count
      assert_equal 10, connected_resources_count
      assert_equal 4, server_connected_users_count(server_env)
      assert_equal 10, server_connected_resources_count(server_env)

      # disconnect 2 of bobs resources
      disconnect_resource bob5
      disconnect_resource bob6

      assert_equal 4, connected_users_count
      assert_equal 8, connected_resources_count
      assert_equal 4, server_connected_users_count(server_env)
      assert_equal 8, server_connected_resources_count(server_env)

      # disconnect jims only resource
      disconnect_resource jim1

      assert_equal 3, connected_users_count
      assert_equal 7, connected_resources_count
      assert_equal 3, server_connected_users_count(server_env)
      assert_equal 7, server_connected_resources_count(server_env)

      # disconnect the rest of bobs resources
      disconnect_resource bob1
      disconnect_resource bob2
      disconnect_resource bob3
      disconnect_resource bob4

      assert_equal 2, connected_users_count
      assert_equal 3, connected_resources_count
      assert_equal 2, server_connected_users_count(server_env)
      assert_equal 3, server_connected_resources_count(server_env)

      # diconnect joes second resource
      disconnect_resource joe2

      assert_equal 2, connected_users_count
      assert_equal 2, connected_resources_count
      assert_equal 2, server_connected_users_count(server_env)
      assert_equal 2, server_connected_resources_count(server_env)

      # disconnect joe and sams only remaining resources
      disconnect_resource joe1
      disconnect_resource sam1

      assert_equal 0, connected_users_count
      assert_equal 0, connected_resources_count
      assert_equal 0, server_connected_users_count(server_env)
      assert_equal 0, server_connected_resources_count(server_env)

      server_offline(server_env)

      assert_equal 0, servers_count

    end

    should "when a server goes offline, everything should be cleaned up" do

      server_env = { :public_addr => "127.0.0.1", :port => 2000 }

      bob1 = connect_new(server_env)
      joe1 = connect_new(server_env)
      jim1 = connect_new(server_env)
      sam1 = connect_new(server_env)

      assert_equal 4, connected_users_count
      assert_equal 4, connected_resources_count
      assert_equal 4, server_connected_users_count(server_env)
      assert_equal 4, server_connected_resources_count(server_env)

      server_offline(server_env)

      assert_equal 0, connected_users_count
      assert_equal 0, connected_resources_count
      assert_equal 0, server_connected_users_count(server_env)
      assert_equal 0, server_connected_resources_count(server_env)

    end

    should "should handle multiple servers" do

      server1 = { :public_addr => "127.0.0.1", :port => 1000 }
      server2 = { :public_addr => "127.0.0.1", :port => 2000 }
      server3 = { :public_addr => "127.0.0.1", :port => 3000 }

      jim1 = connect_new(server1)
      jim2 = connect_new(server2)
      jim3 = add_resource_for_user(server2, jim2[:user_id])

      bob1 = connect_new(server2)
      bob2 = add_resource_for_user(server1, bob1[:user_id])

      assert_equal 2, servers_count

      joe1 = connect_new(server3)

      assert_equal 3, servers_count

      # server 1
      assert_equal 2, server_connected_users_count(server1)
      assert_equal 2, server_connected_resources_count(server1)

      # server 2
      assert_equal 2, server_connected_users_count(server2)
      assert_equal 3, server_connected_resources_count(server2)

      # server 3
      assert_equal 1, server_connected_users_count(server3)
      assert_equal 1, server_connected_resources_count(server3)

      [ jim1, jim2, jim3, bob1, bob2, joe1 ].each do |conn|
        disconnect_resource(conn)
      end

      [ server1, server2, server3 ].each do |server_env|
        assert_equal 0, server_connected_users_count(server_env)
        assert_equal 0, server_connected_resources_count(server_env)
      end

    end

  end
  
end

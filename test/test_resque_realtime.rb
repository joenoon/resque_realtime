require 'helper'

class TestResqueRealtime < Test::Unit::TestCase
  
  context "Resque Realtime" do

    setup do
      redis.flushdb
      Resque::Realtime.clear_callbacks(:resource_connected)
      Resque::Realtime.clear_callbacks(:resource_disconnected)
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
    
    context "callbacks" do
      
      setup do
        $tracker = 0
      end
      
      should "track index of added callbacks" do
        
        5.times do |i|
          cb = Resque::Realtime.add_callback(:resource_connected) { |n| $tracker+=n }
          assert_equal i, cb
        end
        
        assert_equal 5, Resque::Realtime.callbacks[:resource_connected].size
        Resque::Realtime.clear_callback(:resource_connected, 1)
        assert_equal 5, Resque::Realtime.callbacks[:resource_connected].size
        
        assert_equal 0, $tracker
        
        Resque::Realtime.run_callbacks(:resource_connected, 1)
        assert_equal 4, $tracker
        
        $tracker = 0
        
        Resque::Realtime.clear_callbacks(:resource_connected)
        assert_equal 0, Resque::Realtime.callbacks[:resource_connected].size
        
        Resque::Realtime.run_callbacks(:resource_connected, 1)
        assert_equal 0, $tracker
        
      end
      
      context "for dispatching to resources" do
        
        setup do
          $tracker = []
          Resque::Realtime.clear_callbacks(:dispatch_to_resources)
          Resque::Realtime.add_callback :dispatch_to_resources do |server_env, resources, payload|
            $tracker.push({ :server_env => server_env.symbolize_keys, :resources => resources, :payload => payload })
          end

          @server1 = { :public_addr => "127.0.0.1", :port => 1000 }
          @server2 = { :public_addr => "127.0.0.1", :port => 2000 }
          @server3 = { :public_addr => "127.0.0.1", :port => 3000 }

          @jim1 = connect_new(@server1)
          @jim2 = add_resource_for_user(@server2, @jim1[:user_id])
          @jim3 = add_resource_for_user(@server3, @jim1[:user_id])
          @jim4 = add_resource_for_user(@server3, @jim1[:user_id])
          
          # jim has 1 connection to servers 1+2, and 2 connections to server 3
          @jims = [ @jim1, @jim2, @jim3, @jim4 ]

          @bob1 = connect_new(@server2)
          
          # bob has 1 connection to server 2
          @bobs = [ @bob1 ]
          
          @joe1 = connect_new(@server1)
          @joe2 = add_resource_for_user(@server1, @joe1[:user_id])
          @joe3 = add_resource_for_user(@server1, @joe1[:user_id])
          @joe4 = add_resource_for_user(@server2, @joe1[:user_id])
          @joe5 = add_resource_for_user(@server2, @joe1[:user_id])
          @joe6 = add_resource_for_user(@server2, @joe1[:user_id])
          
          # joe has 3 connections to server 1 and 3 connections to server 2
          @joes = [ @joe1, @joe2, @joe3, @joe4, @joe5, @joe6 ]
          
          @payload = [ 'test', { :success => true } ]

        end
        
        should "dispatch twice to send to joe" do
          joes = resource_map_set_of_connection_hashes(@joes)
          Resque::Realtime.dispatch_to_resources(joes, @payload)
          assert_equal 2, $tracker.size
          $tracker.each do |t|
            assert any_of_these_server_envs_match?([ @server1, @server2 ], t[:server_env])
          end
        end

        should "dispatch three times to send to jim" do
          jims = resource_map_set_of_connection_hashes(@jims)
          Resque::Realtime.dispatch_to_resources(jims, @payload)
          assert_equal 3, $tracker.size
          $tracker.each do |t|
            assert any_of_these_server_envs_match?([ @server1, @server2, @server3 ], t[:server_env])
          end
        end

        should "dispatch one time to send to bob" do
          bobs = resource_map_set_of_connection_hashes(@bobs)
          Resque::Realtime.dispatch_to_resources(bobs, @payload)
          assert_equal 1, $tracker.size
          $tracker.each do |t|
            assert any_of_these_server_envs_match?([ @server2 ], t[:server_env])
          end
        end
        
        should "send all" do
          resources = [ @joes, @jims, @bobs ].map {|x| resource_map_set_of_connection_hashes(x) }.flatten
          Resque::Realtime.dispatch_to_resources(resources, @payload)
          assert_equal 3, $tracker.size
          $tracker.each do |t|
            assert any_of_these_server_envs_match?([ @server1, @server2, @server3 ], t[:server_env])
          end
        end
        
      end
      
    end

  end
  
end

require 'rubygems'
require 'sinatra/base'
require 'eventmachine'
require 'thin'

require_relative 'proto'
require_relative 'auth'
require_relative 'model'
require_relative 'app'
require_relative 'connection'
require_relative 'util'

$state = Model::State.new
$connection = nil

def login
    if not $connection.nil?
        $connection.close
    end

    auth = EmailAuth.login
    puts auth
    fail "Email & password authentication failed" unless auth["ok"]

    pregame = EmailAuth.pregame_setup auth["access_token"]
    puts pregame
    
    fail "Pregame setup failed" unless pregame["ok"]

    $connection = Connection.new pregame["serverIp"]
    $connection.write(Protocol.getTicketRequest)
    $state.connection = $connection

    ticket_response = $connection.read
    $connection.write(Protocol.loginRequest(auth, ticket_response["p"]["tk"]))

    # skip responses we're not interested in
    init_response = $connection.waitfor("gs_initialized")
    puts "Logged in successfully"

    # now we've got to request the DBs to behave
    # more like the real client we're emulating
    #Protocol.getAllDbRequests(1408023723000).each do |request|
        # send db request
    #    $connection.write(request)
        # read server response and ignore it
    #    $connection.read
    #end
    #puts "DBs requested"

    # Get promos and quests and ignore them
    #$connection.write(Protocol.getSimpleNamedRequest("gs_promos", Protocol.getSimpleLongPayload("last_updated", 0)))
    #2.times { $connection.read }
    #$connection.write(Protocol.getSimpleNamedRequest("gs_quest", Protocol.getSimpleLongPayload("last_updated", 0)))
    #$connection.read
    #puts "Fetched promos and quests"

    # Request player object
    $connection.write(Protocol.getSimpleNamedRequest("gs_player", Protocol.getSimpleLongPayload("last_updated", 0)))
    $state.updateFromPlayerObject($connection.read["p"]["p"]["player_object"])
    puts "State updated from player object"
end

def collect
    $state.islands.each do |id, island|
        next if island.name == "Gold"
        sleep rand(3..10)

        if island.name != $state.islands[$state.active_island].name
            $connection.write(Protocol.getSimpleNamedRequest("gs_change_island", Protocol.getSimpleLongPayload("user_island_id", id)))
            change_resp = $connection.waitfor("gs_change_island")
            fail "Failed to change active island" unless change_resp["p"]["p"]["success"] == 1
            $state.active_island = id
        end
        puts "Collecting from active island: #{island.name}"

        island.baking.each do |id, baking|
            if baking.finished < Time.now.to_i * 1000
                puts "Baking #{id} finished at #{Util::unixToString(baking.finished)}"
                sleep rand(1..4)
                if baking.finish
                    if $state.coins >= 75000
                        baking.start(Model::FOOD_ID_PIZZA)
                    end
                end
            else
                puts "Baking #{id} not finished yet. Finish: #{Util::unixToString(baking.finished)}"
            end
        end
        shuffled_monsters = Hash[island.monsters.to_a.shuffle]
        shuffled_monsters.each do |id, monster|
            sleep rand(1..4)
            monster.collect
        end
        puts "Collected from all monsters"
    end
end

def process
    login
    collect
    close
end

def schedule
    EventMachine.add_timer rand(3600..5400) do
        EventMachine::defer(proc { process }, proc { schedule })
    end
end

def close
    $connection.close
    $connection = nil
end

EM.next_tick {
    login
    close
    schedule
}

App.run!

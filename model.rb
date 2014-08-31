module Model
    STRUCT_LARGE_BAKERY = 34
    FOOD_ID_PIZZA = 5

    class State
        attr_accessor :islands, :coins, :diamonds, :ethereal_currency,
            :food, :xp, :level, :connection, :active_island

        def initialize
            @islands = Hash.new
            @coins = 0
            @diamonds = 0
            @ethereal_currency = 0
            @food = 0
            @xp = 0
            @level = 0
            @connection = nil
            @active_island = 0
        end

        def populateMonsters(monsters)
            result = Hash.new
            monsters.each do |src|
                dst = Monster.new src["monster"], src["pos_x"], src["pos_y"],
                    src["user_monster_id"],  self
                dst.name = src["name"]
                dst.happiness = src["happiness"]
                dst.level = src["level"]
                dst.last_collection = src["last_collection"]
                result[dst.user_id] = dst
            end
            result
        end

        def populateStructures(structures)
            result = Hash.new
            structures.each do |src|
                dst = Structure.new src["structure"], src["pos_x"], src["pos_y"],
                    src["user_structure_id"], self
                result[dst.user_id] = dst
            end
            result
        end

        def populateBaking(baking)
            result = Hash.new
            baking.each do |src|
                dst = Baking.new src["food_count"], src["user_structure"],
                    src["started_at"], src["finished_at"], src["user_baking_id"],
                        @islands[src["island"]]
                result[dst.user_id] = dst
            end
            result
        end

        def updateFromPlayerObject(player_object)
            player_object["islands"].each do |src|
                dst = Model::Island.new src["island"], self
                @islands[src["user_island_id"]] = dst
                dst.monsters = populateMonsters(src["monsters"])
                dst.structures = populateStructures(src["structures"])
                dst.baking = populateBaking(src["baking"])
            end
            ["coins", "diamonds", "ethereal_currency",
                "food", "xp", "level", "active_island"].each { |v| send("#{v}=", player_object[v]) }
        end
    end

    class Base
        attr_accessor :user_id, :state

        def initialize
            @user_id = 0
            @state = nil
        end

        def genericSuccessPropsRequest(name, payload)
            print "Sending #{name} request... "
            @state.connection.write(Protocol.getSimpleNamedRequest(name, payload))

            response = @state.connection.waitfor(name)
            success = response["p"]["p"]["success"] == 1
            print "#{success} "

            updateProps(response) if success
            puts
            success
        end

        def updateProps(response)
            if response["p"]["p"].key?("properties")
                response["p"]["p"]["properties"].each do |prop|
                    prop.each do |k, v|
                        @state.send("#{k}=", v) if @state.respond_to? "#{k}="
                    end
                end
            end
        end
    end

    class Baking < Base
        attr_accessor :food_count, :started, :finished,
            :user_structure, :island

        def initialize(food_count, structure, started, finished, id, island)
            @food_count = food_count
            @user_structure = island.structures[structure]
            @island = island
            @started = started
            @finished = finished
            @state = island.state
            @user_id = id
        end

        def finish
            puts "Collecting baking: #{user_id}, #{food_count}... "
            genericSuccessPropsRequest("gs_finish_baking",
                Protocol.getSimpleLongPayload("user_baking_id", user_id))
        end

        def start(food_index)
            puts "Restart baking #{food_index} on structure #{@user_structure.user_id}"
            genericSuccessPropsRequest("gs_start_baking",
                Protocol.getStartBakingPayload(food_index, @user_structure.user_id))
        end
    end

    class Island < Base
        NAMES = %w(Plant Cold Air Water Earth Gold Ethereal Shugabush).freeze
        attr_accessor :structures, :monsters, :baking, :island, :name, :state

        def self.getName(id)
            NAMES[id - 1]
        end

        def initialize(island, state)
            @structures = {}
            @monsters = {}
            @baking = {}
            @island = island
            @name = Island.getName(island)
            @state = state
        end
    end

    class Placeable < Base
        attr_accessor :x, :y, :type

        def initialize(type, x, y, id, state)
            @type = type
            @x = x
            @y = y
            @user_id = id
            @state = state
        end
    end

    class Structure < Placeable
    end

    class Monster < Placeable
        attr_accessor :name, :happiness, :level, :last_collection

        @name = ""
        @happiness = 0
        @level = 0
        @last_collection = 0

        def collect
            puts "Collecting from: #{user_id}"
            success = genericSuccessPropsRequest("gs_collect_monster",
                Protocol.getSimpleLongPayload("user_monster_id", user_id))

            if success
                response = @state.connection.waitfor("gs_update_monster")
                last_collection = response["p"]["p"]["last_collection"]
                updateProps(response)
            end
            success
        end
    end
end


require 'digest/md5'
require_relative 'smartfox'

class Protocol
    def self.getTicketRequest()
        get_tkt = SmartFox2X::SFSObject.new
        get_tkt.merge({"api" => "1.0.4", "bin" => SmartFox2X::Term.build(SmartFox2X::TYPE_BYTE, 1), "cl" => "Java::"})
        SmartFox2X::SFSPacket.build(get_tkt, 0, 0)
    end

    def self.loginRequest(user, password, tk)
        puts "Login: #{user}, #{password}, #{tk}"
        login = SmartFox2X::SFSObject.new
        login.merge({"un" => user, "zn" => "MySingingMonsters", "pw" => Digest::MD5.hexdigest(tk + password)})
        client_info = SmartFox2X::SFSObject.new
        client_info.merge({"client_device" => "D6503", "client_os" => "4.4.2",
            "client_platform" => "android", "client_version" => "1.3.5", "last_update_version" => "1.3.5",
            "last_updated" => SmartFox2X::Term.build(SmartFox2X::TYPE_LONG, 1441712026000)})
        login["p"] = client_info
        SmartFox2X::SFSPacket.build(login, 1, 0)
    end

    def self.getSimpleLongPayload(tag, value)
        payload = SmartFox2X::SFSObject.new
        payload[tag] = SmartFox2X::Term.build(SmartFox2X::TYPE_LONG, value)
        payload
    end
    
    def self.getStartBakingPayload(food_index, user_structure)
        payload = getSimpleLongPayload("user_structure_id", user_structure)
        payload["food_index"] = SmartFox2X::Term.build(SmartFox2X::TYPE_INT, food_index)
        payload
    end

    def self.getSimpleNamedRequest(name, payload_obj)
        request = SmartFox2X::SFSObject.new
        request.merge({"c" => name, "p" => payload_obj,
            "r" => SmartFox2X::Term.build(SmartFox2X::TYPE_INT, -1)})
        SmartFox2X::SFSPacket.build(request, 13, 1)
    end

    def self.getAllDbRequests(last_updated)
        ["db_gene", "db_monster", "db_structure", "db_island", "db_island_torches",
         "db_level", "db_store", "db_scratch_offs"].map { |db| getSimpleNamedRequest(db, getSimpleLongPayload("last_updated", last_updated)) }
    end
end


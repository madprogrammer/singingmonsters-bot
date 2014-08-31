require 'socket'
require_relative 'proto'

class Connection
    def initialize(host)
        puts "Connecting to #{host}"
        @conn = TCPSocket.new host, 9933
        @log = Logger.new("network.log")
    end

    def read
        payload = SmartFox2X::SFSPacket.read(@conn).payload
        response = payload.convert
        @log.debug("<=== #{response.inspect}")
        response
    end

    def write(packet)
        raw = packet.to_binary_s
        payload = SmartFox2X::SFSPacket.read(StringIO.new(raw)).payload
        request = payload.convert
        @log.debug("===> #{request.inspect}")
        @conn.write(raw)
        @conn.flush
    end

    def waitfor(name)
        begin
            response = read
        end until response["p"]["c"] == name
        response
    end

    def close
        puts "Closing connection"
        @conn.close
        @log.close
    end
end

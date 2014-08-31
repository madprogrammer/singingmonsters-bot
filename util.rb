class Util
    def self.unixToString(unix)
        Time.at(unix / 1000).to_datetime.strftime("%d.%m.%Y %H:%M:%S %Z")
    end
end

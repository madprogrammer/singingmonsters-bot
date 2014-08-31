require 'yaml'

CONFIG_FILE = "config.yml"

class Settings
  @_settings = {}
  attr_reader :_settings

  def initialize(filename)
    @_filename = filename
    @_settings = YAML::load_file(@_filename) || Hash.new
  end

  def method_missing(name, *args, &block)
    if not args.empty?
      @_settings[name] = args.first
      self
    else
      @_settings[name]
    end
  end

  def save()
    File.open(@_filename, "w") {|file| file.write @_settings.to_yaml }
  end
end

$settings = Settings.new CONFIG_FILE


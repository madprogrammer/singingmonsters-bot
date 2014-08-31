require 'rubygems'
require 'sinatra/base'

require_relative 'proto'
require_relative 'auth'
require_relative 'model'
require_relative 'util'

class App < Sinatra::Base
    configure do
        enable :sessions
        set :bind, '0.0.0.0'
    end

    helpers do
        def datetime(unix)
            Util::unixToString(unix)
        end
    end

    get '/' do
        haml :index, :locals => { :state => $state }
    end
end

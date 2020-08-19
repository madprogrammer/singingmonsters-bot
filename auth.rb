require 'httparty'
require_relative 'settings'

class EmailAuth
  include HTTParty
  format :json

  def self.common_params
    {
      :g => 1,
      :auth_version => "2.0.0",
      :client_version => "2.4.2",
      :device_id => $settings.device_id,
      :device_model => $settings.device_model,
      :device_vendor => $settings.device_vendor,
      :lang => $settings.lang,
      :os_version => $settings.os_version,
      :package => "com.bigbluebubble.singingmonsters.full",
      :platform => "android"
    }
  end

  ##
  # {
  #   "ok": true,
  #   "user_game_id": ["xxxxxxxxxx"],
  #   "login_types": "[email]",
  #   "access_token":"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  #   "token_type": "bearer",
  #   "expires_at": 1597865416
  # }
  def self.login
    params = {
      :u => $settings.email,
      :p => $settings.password,
      :t => "email",
    }
    post("https://auth.bbbgame.net/auth/api/token/", :body => params.merge(common_params))
  end

  ##
  # {
  #   "ok":true,
  #   "serverId": 234,
  #   "serverIp": "34.229.98.56",
  #   "contentUrl": "https:...files.json"
  # }
  def self.pregame_setup(token)
    post("https://msm-auth.bbbgame.net/pregame_setup.php", :body => common_params, :headers => {
      "Authorization" => token
    })
  end
end



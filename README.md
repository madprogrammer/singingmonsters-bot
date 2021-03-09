My Singing Monsters™ bot
=========

Disclaimer
--------------
> My Singing Monsters™ is a registered trademark of Big Blue Bubble Inc.
> SmartFoxServer 2X is developed by gotoAndPlay(). All trademarks referenced herein are the properties of their respective owners. The program is provided "AS IS", only for educational purposes, without warranty of any kind. Developer is not responsible for any loss or damage from its use, including banned accounts, lost game progress etc. I mainly made it available because of the SmartFox2X protocol implementation code, which may be useful for many other games using SmartFox server as their backend.

Description
--------------
The script is a Ruby client for My Singing Monsters game, and tries to behave like the real client, however it doesn't allow to play the game interactively like the real client does. The client implements a subset of SmartFox 2X binary protocol in Ruby (see http://docs2x.smartfoxserver.com/Overview/sfs2x-protocol), and performs the following actions:
 - Login to the SmartFox server
 - Fetch current game state
 - Render the game state in a simple web GUI built with Sinatra (to see the progress without launching the game)
 - Periodically collect coins from all monsters on owned islands
 - Watch for active baking and restart it as it finishes

The client automates routine tasks like periodic collection of coins and food.

Installation (tested on Ubuntu 20.04 LTS running in WSL2)
--------------

```sh
git clone https://github.com/madprogrammer/singingmonsters-bot
cd singingmonsters-bot

sudo apt install ruby ruby-dev ruby-bundler
bundle install --path vendor/bundle
cp -i config.yml.example config.yml
```

##### Configure settings in config.yml

##### Run the script

```sh
bundle exec ruby main.rb
```


License
----

GNU General Public License version 2


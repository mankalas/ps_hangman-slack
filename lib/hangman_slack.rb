require "hangman_slack/version"
require "slack-ruby-bot"

class HangBot < SlackRubyBot::Bot
  command 'hang' do |client, data, match|
    client.say(:text => 'in there', :channel => data.channel)
  end
end

HangBot.run

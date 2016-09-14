require "hangman_slack/version"
require "slack-ruby-bot"
require "hangman"

class HangBotView < Hangman::View
  PLACEHOLDER = '?'

  def initialize(engine:)
    super(:engine => engine)
  end

  def show_state
    build_state_string.chars.join(' ')
  end
end

class HangBot < SlackRubyBot::Bot
  def initialize
    super
  end

  def self.start
    @validator = Hangman::CaseInsensitiveValidator.new
    @word_picker = Hangman::WordPicker.new
    @engine = Hangman::Engine.new(word: @word_picker.pick, lives: 5, validator: @validator)
    @view = HangBotView.new(engine: @engine)
  end

  def self.say(text)
    @client.say(:text => text, :channel => @data.channel)
  end

  command 'start' do |client, data, match|
    @client = client
    @data = data

    say('Okie dokie')
    start
    say("The secret word is #{@view.show_state}")
  end
end

HangBot.run

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

  def self.show_state
    say("#{@view.show_state} (#{@engine.lives} lives remaining)")
  end

  def self.game_started?
    @engine.nil? || @engine.game_over?
  end

  command 'start' do |client, data, match|
    @client = client
    @data = data

    start
    show_state
  end

  command 'guess' do |client, data, match|
    @client = client
    @data = data
    guess = match[:expression]

    if game_started?
      say("There's no game going on")
    elsif !@view.input_sane?(guess)
      say("'#{guess}' is not a valid input.")
    else
      @engine.guess(guess)
      if @engine.win?
        say("You've won! The word was '#{@engine.word}'")
      elsif @engine.lost?
        say("You've lost! The word was '#{@engine.word}'")
      else
        show_state
      end
    end
  end

  command 'state' do |client, data, match|
    @client = client
    @data = data

    if game_started?
      say("There's no game going on")
    else
      show_state
    end
  end
end

HangBot.run

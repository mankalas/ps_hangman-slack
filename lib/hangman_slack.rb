require "hangman_slack/version"
require "slack-ruby-bot"
require "hangman"

SlackRubyBot.configure do |config|
  config.aliases = ['hg', 'hang']
end

class HangBotView < Hangman::View
  PLACEHOLDER = '?'

  def initialize(engine:)
    super(:engine => engine)
  end

  def show_state
    build_state_string.chars.join(' ')
  end
end

class HangBotWordPicker
  def pick
    ENV['SECRET_WORD'] || Hangman::WordPicker.new.pick
  end
end

class HangBot < SlackRubyBot::Bot
  @@leaderboard = {}

  def self.start
    say("Let's start a game")
    @validator = Hangman::CaseInsensitiveValidator.new
    @word_picker = HangBotWordPicker.new
    @engine = Hangman::Engine.new(word: @word_picker.pick, lives: 8, validator: @validator)
    @view = HangBotView.new(engine: @engine)
    #    show_state
  end

  def self.say(text)
    @client.say(:text => text, :channel => @data.channel)
  end

  def self.show_state
    say("#{@view.show_state} (#{@engine.lives} lives remaining)")
    say("Already guessed #{@validator.guessed_letters.to_a.join(', ')}")
  end

  def self.has_game?
    !@engine.nil? && !@engine.game_over?
  end

  def self.game_started?
    say("There's no game going on") unless res = has_game?
    res
  end

  def self.no_game?
    say("A game has already started") unless res = !has_game?
    res
  end

  def self.valid_input?(guess)
    say("'#{guess}' is not a valid input") unless res = @view.input_sane?(guess)
    res
  end

  def self.start_command(client, data)
    @client = client
    @data = data
  end

  def self.init_user_score(user)
    @@leaderboard[user] = 0 unless @@leaderboard.has_key?(user)
  end

  def self.correct_guess(user)
    say("GG <@#{user}>, you've guessed correctly")
    @@leaderboard[user] += 2
  end

  def self.incorrect_guess(user)
    say("Too bad <@#{user}>, you've guessed poorly")
    @@leaderboard[user] -= 1
  end

  def self.show_game_state
    if @engine.win?
      say("You've won! The word was '#{@engine.word}'")
      @@leaderboard[data.user] += @engine.word.length
    elsif @engine.lost?
      say("You've lost! The word was '#{@engine.word}'")
    else
      show_state
    end
  end

  command 'start' do |client, data, match|
    start_command(client, data)

    start if no_game?
  end

  command 'guess' do |client, data, match|
    start_command(client, data)
    guess = match[:expression]

    if game_started? && valid_input?(guess)
      user = data.user
      init_user_score(user)

      @engine.guess(guess) ? correct_guess(user) : incorrect_guess(user)
      show_game_state
    end
  end

  command 'state' do |client, data, match|
    start_command(client, data)

    show_state if game_started?
  end

  command 'word' do |client, data, match|
    start_command(client, data)
    word = match[:expression]

    if game_started?
      user = data.user
      init_user_score(user)

      @engine.guess_word(word) ? correct_guess(user) : incorrect_guess(user)
      show_game_state
    end
  end

  command 'scores' do |client, data, match|
    start_command(client, data)

    @@leaderboard.each do |key, value|
      say("<@#{key}> has #{value} point(s).")
    end
  end

  command 'reset' do |client, data, match|
    start_command(client, data)

    @engine = @validator = @view = nil
    @@leaderboard = {}
    say("Back to zero")
  end
end

#HangBot.run

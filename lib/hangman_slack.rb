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
  help do
    title 'Hangman Bot'
    desc "You miss DevTrain? You like Slack? Now, you can play Hangman on Slack! :partyparrot:\n\n" \
         "In order to play, you must tell the moderator what command to execute (`hg start`).\n\n" \
         "There is a pretty unfair system of score that goes on forever, that is unless someone enters 'reset' command.\n\n" \
         "Thanks to Van for the starting pointers and Tiger for the Slack admin stuff."

    command 'start' do
      desc "Starts a new game, ie. ask you to guess a new word."
    end

    command 'guess' do
      desc "Submit a guess obviously. Mind the space(s) between the command and your guess."
    end

    command 'word' do
      desc "If you have what it takes, you can try to guess the whole word. Mind the space(s) between the command and your guess."
    end

    command 'state' do
      desc "Displays the state of the game, ie. the masked word, the gallow and the letters that have already been guessed."
    end

    command 'score' do
      desc "Displays the leaderboard, in no particular order, which is an order by itself."
    end

    command 'reset' do
      desc "Reset the leaderboard. Mainly used by losers."
    end

  end

  @@leaderboard = {}

  def self.start
    say("Let's start a game")
    @validator = Hangman::CaseInsensitiveValidator.new
    @word_picker = HangBotWordPicker.new
    @engine = Hangman::Engine.new(word: @word_picker.pick, lives: 6, validator: @validator)
    @view = HangBotView.new(engine: @engine)
    show_state
  end

  def self.say(text)
    @client.say(:text => text, :channel => @data.channel)
  end

  def self.show_state
    say("#{@view.show_state} :hang#{@engine.lives + 1}:") #+1 because I can't count
    guesses = @validator.guessed_letters
    say("Already guessed #{guesses.to_a.join(', ')}") if !guesses.empty?
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
    else
      show_state
      say("You've lost! The word was '#{@engine.word}'") if @engine.lost?
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

      if @engine.guess_word(word)
        say("You've find the word #{@engine.word}! Congrats!")
        @@leaderboard[user] += @engine.word.length + 5
      else
        incorrect_guess(user)
        show_
      end
    end
  end

  command 'score' do |client, data, match|
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

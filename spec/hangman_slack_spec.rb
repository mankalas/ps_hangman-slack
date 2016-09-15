require 'spec_helper'

require 'spec_helper'

describe HangmanSlack do
  it 'has a version number' do
    expect(HangmanSlack::VERSION).not_to be nil
  end

  before do
    ENV['SECRET_WORD'] = "PowerForm"
  end

  after do
    expect(message: "#{SlackRubyBot.config.user} reset").to respond_with_slack_message('Back to zero')
  end

  it 'says hi' do
    expect(message: "#{SlackRubyBot.config.user} hi").to respond_with_slack_message('Hi <@user>!')
  end

  context "no game is going on" do
    describe "start" do
      it 'starts a new game' do
        expect(message: "#{SlackRubyBot.config.user} start").to respond_with_slack_message("Let's start a game")
      end
    end

    describe "guess" do
      it "err" do
        expect(message: "#{SlackRubyBot.config.user} guess e").to respond_with_slack_message("There's no game going on")
      end
    end
  end

  context "a game is going on" do
    before do
      expect(message: "#{SlackRubyBot.config.user} start").to respond_with_slack_message("Let's start a game")
    end

    describe "start" do
      it "doesn't start a game twice" do
        expect(message: "#{SlackRubyBot.config.user} start").to respond_with_slack_message("A game has already started")
      end
    end

    describe "guess" do
      it "err on bad input" do
        %w{1 ! qw}.each do |input|
          expect(message: "#{SlackRubyBot.config.user} guess #{input}").to respond_with_slack_message("'#{input}' is not a valid input")
        end
      end
    end
  end
end

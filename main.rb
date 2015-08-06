require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'ankesh' 

BLACKJACK_NUMBER = 21
DEALER_MINIMUM = 17

helpers do
  def total(player_or_dealer_cards)
    cards = player_or_dealer_cards
    total = 0

    cards.each do |card|
      if [2, 3, 4, 5, 6, 7, 8, 9, 10].include?(card[1].to_i)
        total += card[1].to_i
      elsif ["jack", "queen", "king"].include?(card[1])
        total += 10
      elsif ["ace"].include?(card[1])
        total += 1
      end
    end

    # correct for aces
    cards.each do |card|
      if card[1] == "ace" && total < 12
        total += 10
      end
    end

    total
  end

  def card_image(card)

    "<img src= '/images/cards/#{card[0]}_#{card[1]}.jpg' />"
  end
end

before do
  @hit_or_stay_buttons = true
  @dealer_turn = false
  @dealer_show_first_card = false
end

get '/' do
  if !session[:player_name] || !session[:total_amount]
    redirect '/player_name_amount_form'
  else
    redirect '/game'
  end
end

get '/player_name_amount_form' do
  erb :player_name_amount_form
end

post '/player_name_amount_form' do
  if params[:player_name].empty?
    @error = "A name is required to play the game"
    halt erb :player_name_amount_form
  elsif params[:total_amount].empty? || params[:total_amount].to_f == 0.0
    @error = "You need to enter a number for total amount"
    halt erb :player_name_amount_form  
  end

  session[:player_name] = params[:player_name]
  session[:total_amount] = params[:total_amount]
  redirect '/bet_amount'
end

get '/bet_amount' do

  erb :bet_amount
end

post '/bet_amount' do

  if params[:bet_amount].empty? || params[:bet_amount].to_f == 0.0
    @error = "You need to enter a number for bet amount"
    halt erb :bet_amount
  elsif params[:bet_amount] > session[:total_amount]
    @error = "You can't bet more than what you have" 
    halt erb :bet_amount
  end

  session[:bet_amount] = params[:bet_amount]

  redirect '/game'
end

get '/game' do
  suit = ["spades", "hearts", "clubs", "diamonds"]
  card_values = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
  deck = suit.product(card_values)
  session[:cards] = deck.shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []

  session[:player_cards] << session[:cards].pop
  session[:dealer_cards] << session[:cards].pop
  session[:player_cards] << session[:cards].pop
  session[:dealer_cards] << session[:cards].pop

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:cards].pop
  if total(session[:player_cards]) > BLACKJACK_NUMBER
    @error = "Sorry, #{session[:player_name]} has busted!"
    @hit_or_stay_buttons = false
  end
  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay!"
  @hit_or_stay_buttons = false
  @dealer_turn = true
  redirect '/game/dealer'
end

get '/game/dealer' do

  @hit_or_stay_buttons = false
  @dealer_show_first_card = true

  if total(session[:dealer_cards]) <= DEALER_MINIMUM
    @dealer_turn = true
  elsif total(session[:dealer_cards]) > BLACKJACK_NUMBER
    @success = "Dealer has busted! #{session[:player_name]} wins!"
  elsif total(session[:dealer_cards]) == total(session[:player_cards])
    @success = "Both #{session[:player_name]} and Dealer have #{total(session[:player_cards])} points. Its a tie."
  elsif total(session[:dealer_cards]) > total(session[:player_cards])
    @error = "#{session[:player_name]} has #{total(session[:player_cards])} points and Dealer has #{total(session[:dealer_cards])} points. #{session[:player_name]} loses."  
  elsif total(session[:dealer_cards]) < total(session[:player_cards])
    @success = "#{session[:player_name]} has #{total(session[:player_cards])} points and Dealer has #{total(session[:dealer_cards])} points. #{session[:player_name]} wins."  
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:cards].pop

  redirect '/game/dealer'
end

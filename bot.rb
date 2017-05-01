#!/usr/bin/env ruby

require 'yaml'
require 'Twitter'

puts '****************************************'
puts 'Welcome, type `bot_help` for help.'
puts '****************************************'

# Global variables
@client = nil

# Loads an account based on the secrets YAML file
def load(user)
  accounts = YAML.load_file('secrets.yml')
  user_account = accounts[user]
  return false if user_account.nil?
  @client = Twitter::REST::Client.new do |config|
    config.consumer_key        = user_account['consumer_key']
    config.consumer_secret     = user_account['consumer_secret']
    config.access_token        = user_account['access_token']
    config.access_token_secret = user_account['access_token_secret']
  end
  @followers = @client.follower_ids
  true
end

def search(query, amount: 50, options: {})
  @client.search(query, options).take(amount)
end

def fav(query, options: {}, amount: 50, skip: true, one_per_query: true)
  return if query.empty?
  faved = 0
  faved_users = []
  tweets = search(query, amount: amount, options: options)
  tweets.each do |tweet|
    if skip && @followers.include?(tweet.user.id)
      puts "Skipped(@#{tweet.user.screen_name}): #{tweet.text}"
      next
    end
    if one_per_query && faved_users.include?(tweet.user.id)
      puts "Skipped(@#{tweet.user.screen_name}): #{tweet.text}"
      next
    end
    @client.favorite(tweet)
    faved_users << tweet.user.id
    faved += 1
    puts "Faved(@#{tweet.user.screen_name}): #{tweet.text}"
  end
  puts "Faved #{faved} tweets."
  faved
end

def reply(query, options: {}, amount: 50, skip: true, one_per_query: true)
  return if query.empty?
  replied = 0
  replied_users = []
  tweets = search(query, amount: amount, options: options)
  tweets.each do |tweet|
    if skip && @followers.include?(tweet.user.id)
      puts "Skipped(@#{tweet.user.screen_name}): #{tweet.text}"
      next
    end
    if one_per_query && replied_users.include?(tweet.user.id)
      puts "Skipped(@#{tweet.user.screen_name}): #{tweet.text}"
      next
    end
    @client.update("@#{tweet.user.screen_name} ¡Hey!",
                   in_reply_to_status_id: tweet.id)
    replied_users << tweet.user.id
    replied += 1
    puts "Replied(@#{tweet.user.screen_name}): #{tweet.text}"
  end
  puts "Replied #{replied} tweets."
end

def reply_book_loop(query, options: {})
  return if query.empty?
  replied_tweets = []
  total_replied = 0
  loop do
    replied = 0
    puts "#{Time.new}: Started replying..."
    tweets = search(query, options: options)
    tweets.each do |tweet|
      next if replied_tweets.include?(tweet.id)
      @client.update("@#{tweet.user.screen_name} \"#{random_book}\" @BogotaRuby #RubyDev #Filbo2017",
                     in_reply_to_status_id: tweet.id)
      replied_tweets << tweet.id
      replied += 1
      puts "Replied(@#{tweet.user.screen_name}): #{tweet.text}"
    end
    total_replied += replied
    puts "New #{replied} replies, out of #{total_replied} total replies."
    puts 'Sleeping...'
    sleep(5) # Wait for 5 seconds until replying again
  end
end

def common_options(lang: true, geocode: true)
  opts = {}
  opts[:lang] = 'es' if lang # Spanish only tweets
  opts[:geocode] = '4.753,-74.113,1150km' if geocode # Colombia (and a bit more around)
  opts
end

def random_book
  [
    'Business Model Generation (Alexander Osterwalder)',
    'Digital Wars (Charles Arthur)',
    'El diario de Anna Frank',
    'Elon Musk: Tesla, SpaceX, and the Quest for a Fantastic Future (Ashlee Vance)',
    'Getting Real (37signals)',
    'How to win friends and influence people (Dale Carnegie)',
    'Las cuatro vidas de Steve Jobs (Daniel Ichbiah)',
    'Los Innovadores (Walter Isaacson)',
    'Rework (Jason Fried)',
    'Rojo Sombra (Gabriela A. Arciniegas)',
    'Slicing Pie: Fund Your Company Without Funds (Mike Moyer)',
    'The 4-Hour Workweek (Timothy Ferriss)',
    'The Founder\'s Dilemmas (Noam Wasserman)',
    'The Great Design (Stephen Hawking, Leonard Mlodinow)',
    'The Lean Startup (Eric Ries)',
    'Zero to One (Peter Thiel)'
  ].sample
end

def bot_help
  puts '****************************************'
  puts "How to use this simple bot:

1. Load an account doing

  load(account_name)

  # Or whatever screen name you have

2. Seach for some tweets doing

  search(query, options)

  e.g.
  search(
    '#StarWars',
    options: {
      lang: 'es',
      geocode: '4.753,-74.113,1150km'
    }
  )

3. Fav some tweets doing

  fav(query, options, amount, skip, one_per_query)

  e.g.
  fav(
    '#Motorbike',
    options: {
      lang: 'en',
      geocode: '4.753,-74.113,1150km'
    },
    amount: 100
  )

5. More will be added, eventually."
  puts '****************************************'
end

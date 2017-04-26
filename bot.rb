#!/usr/bin/env ruby

require 'yaml'
require 'Twitter'

puts '****************************************'
puts 'Welcome, type `bot_help` for help.'
puts '****************************************'
@client = nil

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

def fav(query, options: {}, amount: 50, skip: true, one_per_query: true)
  return if query.empty?
  faved = 0
  faved_users = []
  @client.search(query, options).take(amount).each do |tweet|
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

def search(query, amount: 50, options: {})
  @client.search(query, options).take(amount)
end

def common_options(lang: true, geocode: true)
  opts = {}
  opts[:lang] = 'es' if lang # Spanish only tweets
  opts[:geocode] = '4.753,-74.113,1150km' if geocode # Colombia (and a bit more around)
  opts
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

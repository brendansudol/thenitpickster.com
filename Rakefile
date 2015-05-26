require 'httparty'
require 'open-uri'
require './app'

task :fetch_one_and_send_one do
  run_or_not = (0..3).to_a.sample
  if run_or_not != 1
    puts "Not running this time :("
  else
    puts "Go Time!\n"
    id = ""
    repeats = 0
    additions = 0
    nit_number = (0..(@nits.length - 1)).to_a.sample
    nit_to_pick = @nits[nit_number]

    puts "Fetching a new tweet..."
    # define new url
    wrong_phrase = nit_to_pick[0]
    proper_phrase = nit_to_pick[1]
    url = make_twitter_url(wrong_phrase)
    # fetch json data
    # OLD WAY: data = HTTParty.get(url)
    data = Twitter.search("\"#{wrong_phrase}\" -rt", count: MAX_TWEETS_PER_QUERY)
    tweets = data['results']
    # loop through tweets
    tweets.each do |tweet|
      id = tweet['id'].to_s
      # add them to db if not already there
      if Tweet.all(:tweet_id => id).length == 0
        additions += 1
        t = Tweet.new
        t.tweet_id = id
        t.user_name = tweet['from_user']
        t.user_id = tweet['from_user_id'].to_s
        t.message = tweet['text']
        t.wrong_usage = wrong_phrase
        t.proper_usage = proper_phrase
        t.created_at = Time.now
        t.updated_at = Time.now
        t.save
      else
        repeats += 1
      end
    end
    puts "Phrase: #{wrong_phrase}; #{additions} new entries; #{repeats} repeat entries\n"

    puts "Sending that tweet..."
    tweet_to_send = Tweet.all(:tweet_id => id)[0]
    url_for_sending = "http://www.nitpickler.com/send/specific/#{tweet_to_send.id}"
    data = HTTParty.get(url_for_sending)
    puts data
  end
end

######################################################
## old / testing rake tasks below
## maybe helpful to reference
######################################################

task :refresh_data do
  puts "Starting refresh..."
  open('http://www.nitpickler.com/fetch-tweets')
  sleep 5.0 + rand
  open('http://www.nitpickler.com/send-tweets')
  puts "Done."
end

task :test_db do
  array = []
  tweets = Tweet.all
  tweets.each do |t|
    array << t.wrong_usage
  end
  puts "#{array.join(' ')}"
end

task :test_pinger do
  url = "http://www.nitpickler.com/send-tweets"
  data = HTTParty.get(url)
  puts data
end

task :test do
  a = @nits
  puts a
end

task :fetch_one, :nit do |t, args|
  nitpicks = @nits
  nit = args[:nit]
  repeats = 0
  additions = 0
  wrong_phrase = nit.split('+').join(" ")
  el = nitpicks.index(nitpicks.find_all{|n| n[0] == wrong_phrase }[0])
  if el.nil?
    puts "not on the list :("
  else
    proper_phrase = nitpicks[el][1]
    url = make_twitter_url(wrong_phrase)
    data = HTTParty.get(url)
    tweets = data['results']
    tweets.each do |tweet|
      id = tweet['id']
      if Tweet.all(:tweet_id => id).length == 0
        additions += 1
        t = Tweet.new
        t.tweet_id = id.to_s
        t.user_name = tweet['from_user']
        t.user_id = tweet['from_user_id'].to_s
        t.message = tweet['text']
        t.wrong_usage = wrong_phrase
        t.proper_usage = proper_phrase
        t.created_at = Time.now
        t.updated_at = Time.now
        t.save
      else
        repeats += 1
      end
    end
    puts "#{additions} new entries; #{repeats} repeat entries; #{wrong_phrase}; #{proper_phrase}; #{url}"
  end
end

task :fetch_data do
  repeats = 0
  additions = 0
  @nits.each do |nit|
    # define new url
    wrong_phrase = nit[0]
    proper_phrase = nit[1]
    url = make_twitter_url(wrong_phrase)
    # fetch json data
    data = HTTParty.get(url)
    tweets = data['results']
    # loop through tweets
    tweets.each do |tweet|
      id = tweet['id']
      # add them to db if not already there
      if Tweet.all(:tweet_id => id).length == 0
        additions += 1
        t = Tweet.new
        t.tweet_id = id.to_s
        t.user_name = tweet['from_user']
        t.user_id = tweet['from_user_id'].to_s
        t.message = tweet['text']
        t.wrong_usage = wrong_phrase
        t.proper_usage = proper_phrase
        t.created_at = Time.now
        t.updated_at = Time.now
        t.save
      else
        repeats += 1
      end
    end
  end
  puts "Complete: #{additions} new entries; #{repeats} repeat entries"
end

task :test_test do
  run_or_not = (0..3).to_a.sample
  if run_or_not != 1
    puts "Not running this time :("
  else
    puts "Go Time!\n"
  end
end
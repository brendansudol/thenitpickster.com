require 'sinatra'
require 'data_mapper'
require 'chronic'
require 'nokogiri'
require 'httparty'
require 'open-uri'
require 'uri'
require 'twitter'
require 'pony'
require 'sinatra/flash'

enable :sessions

# constants
MAX_TWEETS_PER_QUERY = 1
EXAMPLE_IMAGES = 7

# first el is wrong usage, second el is proper usage
nitpicks =  [
            # ["reed a book", "read a book"],
            ["about who to", "about whom to"],
            ["baited breath", "bated breath"],
            ["bare in mind", "bear in mind"],
            ["brake a leg", "break a leg"],
            ["hit the breaks", "hit the brakes"],
            ["larger then", "larger than"],
            ["loosing record", "losing record"],
            ["loosing the", "losing the"],
            ["out of sink", "out of sync"],
            ["per say", "per se"],
            ["easier then", "easier than"],
            ["imminent domain", "eminent domain"],
            ["loosing streak", "losing streak"],
            ["loosing team", "losing team"],
            ["affect upon", "effect upon"],
            ["agree in principal", "agree in principle"],
            ["rather then", "rather than"],
            ["mute point", "moot point"],
            ["for all intensive purposes", "for all intents and purposes"],
            ["dually noted", "duly noted"],
            # ["specific ocean", "pacific ocean"]
            ]

# for my rake tasks
@nits = nitpicks

def make_twitter_url(query)
  base = "http://search.twitter.com/search.json?q=%22"
  suffix = "%22%20-RT&rpp=#{MAX_TWEETS_PER_QUERY}"
  encoded_query = URI.escape(query)
  return base + encoded_query + suffix
end

# setting twitter config variables
Twitter.configure do |config|
  config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
  config.oauth_token = ENV['TWITTER_OAUTH_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_OAUTH_SECRET']
end

# db for storing tweets
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/my.db")
class Tweet
  include DataMapper::Resource
  property :id, Serial
  property :tweet_id, String
  property :user_name, String
  property :user_id, String
  property :message, Text, :length => 300
  property :wrong_usage, String
  property :proper_usage, String
  property :responded, Boolean, :default  => false
  property :created_at, DateTime
  property :updated_at, DateTime
end
DataMapper.finalize.auto_upgrade!

# landing page
get '/' do
  @pics_shuffled = (1..EXAMPLE_IMAGES).to_a.shuffle
  @random_pic_num = @pics_shuffled.pop
  erb :home
end

# list of all nitpicks
get '/nitpicks' do
  @nitpicks = nitpicks
  erb :nitpicks
end

# fetch new tweets and put them in db
get '/fetch/:query' do
  repeats = 0
  additions = 0
  wrong_phrase = params[:query].split('+').join(" ")
  el = nitpicks.index(nitpicks.find_all{|nit| nit[0] == wrong_phrase }[0])
  if el.nil?
    "not on the list :("
  else
    proper_phrase = nitpicks[el][1]
    data = Twitter.search("\"#{wrong_phrase}\" -rt", count: MAX_TWEETS_PER_QUERY)
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
    "#{additions} new entries; #{repeats} repeat entries; #{wrong_phrase}; #{proper_phrase}"
  end
end

# loop through new tweets in db, and send response
get '/send-tweets' do
  sent_tweets = 0
  failed_sends = 0
  tweets = Tweet.all(:responded => false, :order => :created_at.asc, :limit => 1)
  tweets.each do |t|
    begin
      Twitter.update("@#{t.user_name}: I think you mean, '#{t.proper_usage}' :)", {:in_reply_to_status_id => t.tweet_id})
    rescue
      failed_sends += 1
    else
      sent_tweets += 1
    ensure
      sleep 0.0 + (rand / 2)
      t.responded = true
      t.save
    end
  end
  "Complete: #{sent_tweets} tweets sent; #{failed_sends} tweets failed"
end

# send email with nitpick suggestion
post '/nitpicks' do
  suggestion = params[:suggestion]
  Pony.mail(
    :to => 'brendan@etsy.com',
    :subject => "TheNitPickster Suggestion",
    :body => suggestion,
    :port => '587',
    :via => :smtp,
    :via_options => {
      :address              => 'smtp.gmail.com',
      :port                 => '587',
      :enable_starttls_auto => true,
      :user_name            => 'thenitpickster',
      :password             => ENV['EMAIL_PASSWORD'],
      :authentication       => :plain,
      :domain               => 'gmail.com'
    })
  flash[:success] = "Suggestion sent. Thanks for your help!"
  redirect '/nitpicks'
end

######################################################
## various routes for testing / checking purposes
######################################################

# for db debugging
get '/debug' do
  @db_tweets = Tweet.all(:order => [ :created_at.desc ])
  erb :debug
end

# to send out response to specific row id
get '/send/specific/:id' do
  sent_tweets = 0
  failed_sends = 0
  id = params[:id].to_i
  t = Tweet.get(id)
  if t.nil?
    "not on the list :("
  else
    begin
      Twitter.update("@#{t.user_name}: I think you mean, '#{t.proper_usage}' :)", {:in_reply_to_status_id => t.tweet_id})
    rescue
      failed_sends += 1
    else
      sent_tweets += 1
    ensure
      t.responded = true
      t.save
    end
    "Complete: #{sent_tweets} tweets sent; #{failed_sends} tweets failed"
  end
end

# to flush out all unresponded tweets
get '/flush' do
  counter = 0
  tweets = Tweet.all(:responded => false)
  tweets.each do |t|
    counter += 1
    t.responded = true
    t.save
  end
  "#{counter} tweets flushed out."
end

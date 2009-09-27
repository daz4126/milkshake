require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'

# Database connection
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/test.db")

$LOAD_PATH.unshift(File.dirname(__FILE__) + "/lib")
require 'auth'
require 'page'

DataMapper.auto_upgrade!

# App Settings
SITE_NAME = "Milkshake"
USER_NAME = "admin"
PASSWORD  = "vanilla"

# Helpers
helpers do
def link_to(url,text,opts={})
  attributes = ""
  opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
  "<a href=\"#{url}\" #{attributes}>#{text}</a>"
end
end

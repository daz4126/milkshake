require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'

# Database connection
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/test.db")

require 'auth'
require 'page'
require 'helpers'

DataMapper.auto_upgrade!

# App Settings
SITE_NAME = "Milkshake"
USER_NAME = "admin"
PASSWORD  = "vanilla"

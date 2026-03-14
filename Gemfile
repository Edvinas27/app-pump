# frozen_string_literal: true

source "https://rubygems.org"

gem "bcrypt"
gem "dotenv"
gem "interactor-initializer"
gem "jwt"
gem "maxmind-geoip2"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "rails", "~> 8.0.4"
gem "rubocop", require: false
gem "rubocop-rails", require: false
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
end

group :test do
  gem "factory_bot"
  gem "factory_bot_rails"
  gem "rspec"
  gem "rspec-rails"
end

group :development do
  gem "rubocop-rails-omakase", require: false
end

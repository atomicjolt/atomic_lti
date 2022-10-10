source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in atomic_lti.gemspec.
gemspec

group :development do
  gem 'sqlite3'
end


group :development, :test do
  gem 'byebug'
  gem "factory_bot_rails"
  gem "webmock"
end

group :test do
  gem "capybara"
  gem "database_cleaner"
  gem "launchy"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "webmock"
  gem "rspec"
  gem "rspec-rails"
end

# To use a debugger
# gem 'byebug', group: [:development, :test]

gem "jwt", "2.3.0"
gem "json-jwt", "1.13.0"
gem "httparty", "0.20.0"

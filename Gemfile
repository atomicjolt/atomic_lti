source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem"s dependencies in atomic_lti.gemspec.
gemspec

gem "composite_primary_keys"

group :development do
  gem "sqlite3"
end


group :development, :test do
  gem "byebug"
  gem "factory_bot_rails"
  gem "webmock"
end

group :test do
  gem "capybara"
  gem "database_cleaner"
  gem "launchy"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "rspec"
  gem "rspec-rails"

  gem "jwt", "2.3.0"
  gem "json-jwt", "1.13.0"
  gem "httparty", "0.20.0"
end

# To use a debugger
# gem "byebug", group: [:development, :test]

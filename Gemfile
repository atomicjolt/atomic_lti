source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem"s dependencies in atomic_lti.gemspec.
gemspec

gem "composite_primary_keys"

group :development do
  gem "sqlite3"
end


group :development, :test, :linter do
  gem "byebug"
  gem "factory_bot_rails"
  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "webmock"
end

group :test do
  gem "launchy"
  gem "rspec"
  gem "rspec-rails"

  gem "jwt", "2.3.0"
  gem "json-jwt", "1.13.0"
  gem "httparty", "0.21.0"
end

group :ci do
  gem "brakeman"
  gem "pronto"
  gem "pronto-rubocop", require: false
end

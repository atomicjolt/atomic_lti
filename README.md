# AtomicLti
Atomic LTI implements the LTI Advantage specification.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "atomic_lti"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install atomic_tenant
```

Then install the migrations:
./bin/rails atomic_lti:install:migrations

## Usage
Create a new initializer:
  ```
  config/initializers/atomic_lti.rb
  ```

with the following contents. Adjust paths as needed.

  ```
  AtomicLti.oidc_init_path = "/oidc/init"
  AtomicLti.oidc_redirect_path = "/oidc/redirect"
  AtomicLti.target_link_path_prefixes = ["/lti_launches"]
  AtomicLti.default_deep_link_path = "/lti_launches"
  AtomicLti.jwt_secret = Rails.application.secrets.auth0_client_secret
  AtomicLti.scopes = AtomicLti::Definitions.scopes.join(" ")
  ```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

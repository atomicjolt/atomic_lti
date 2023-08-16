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
$ gem install atomic_lti
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

Add the middleware configuration to application.rb (assuming AtomicTenant is in use)
  ```
  config.middleware.insert_before AtomicTenant::CurrentApplicationInstanceMiddleware, AtomicLti::OpenIdMiddleware
  config.middleware.insert_before AtomicLti::OpenIdMiddleware, OidcCompatabilityMiddleware
  config.middleware.insert_before AtomicLti::OpenIdMiddleware, AtomicLti::ErrorHandlingMiddleware
  ```

## Building javascript
Run esbuild:
  ```
  yarn build
  ```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Timeout

Timeout provides a way to auto-terminate a potentially long-running
operation if it hasn't finished in a fixed amount of time.

Previous versions didn't use a module for namespacing, however
#timeout is provided for backwards compatibility.  You
should prefer Timeout.timeout instead.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'timeout'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install timeout

## Usage

```ruby
require 'timeout'
status = Timeout::timeout(5) {
  # Something that should be interrupted if it takes more than 5 seconds...
}
```

Handling timeout  termination 

```ruby
begin 
  status = Timeout::timeout(5) {
    # Something that should be interrupted if it takes more than 5 seconds...
  }
rescue Timeout::Error
  puts 'The process has taken longer than expected'
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/timeout.

[![Build Status](https://travis-ci.org/deep-cover/deep-cover.svg?branch=master)](https://travis-ci.org/deep-cover/deep-cover)

# DeepCover

Deep Cover aims to be an improved replacement for the built-in Coverage library.

It will report a more accurate picture of your code usage. In particular a line is considered covered if and only if it is entirely executed:

    foo if false  # => This is considered covered by builtin coverage, even though `foo` might not even exist

Optionally, branch coverage will detect if some branches are never taken. In the following example, `test_foo` only provides values for `x` that respond to `:to_s`, thus the implicit `else` is never tested (i.e. a value of `x` that does not respond to `:to_s`)

  def foo(x)
    x = x.to_s if x.respond_to? :to_s
    # ...
  end

  def test_foo
    assert_equal something, foo(42)
    assert_equal something_else, foo(:hello)
  end

## Installation

Add to your Gemfile:

    gem 'deep-cover'

Then run:

    bundle

### Builtin Coverage (including SimpleCov) users

Before you require `coverage` or `simplecov`, do a `require 'deep-cover/takeover'`.

For example, the `test/test_helper.rb` file for `simplecov` users will look like

```
require 'deep-cover/takeover'
require 'simplecov'
SimpleCov.start
# rest of `test_helper.rb`
```

### Quick and dirty for Rails app or Gem:

Assuming your default `rake` task is set to execute all tests, you can try:

`deep-cover /path/to/rails/app/or/gem`

## Usage

### Configuration

`configure` is used to specify how specific `DeepCover` should be and which files it should analyse. The following code reflects the default settings:

```
DeepCover.configure do
  cover_paths %w[app lib]
  require_all_expression_in_line
  require_all_branches(false)
  accept_uncovered_raise(false)
  accept_uncovered_default_arguments(false)
end
```

### Low level usage

```
# Setup
require 'deep-cover'
DeepCover.configure { require_all_branches }
# Cover
DeepCover.cover do
  require 'my_file_to_cover'
  require 'my_other_file_to_cover'
end
require 'this_file_wont_be_covered'
tests.run()
DeepCover.report
```

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

For detailed analysis:

`deep-cover -e "some.ruby(:code).here"`

To run one of the specs in `spec`:

`deep-cover -t boolean`

## Contributing

Please ask questions on StackOverflow.com. Maintainers monitor the tag `deep-cover.rb`.

Bug reports and pull requests are welcome on GitHub at https://github.com/deep-cover/deep-cover. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DeepCover project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/deep-cover/deep-cover/blob/master/CODE_OF_CONDUCT.md).

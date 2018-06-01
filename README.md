[![Build Status](https://travis-ci.org/deep-cover/deep-cover.svg?branch=master)](https://travis-ci.org/deep-cover/deep-cover)

# DeepCover

Deep Cover aims to be the best coverage tool for Ruby code:

* more accurate line coverage
* branch coverage
* can be used as a drop-in replacement for the built-in Coverage library.

It reports a more accurate picture of your code usage. In particular a line is considered covered if and only if it is entirely executed:

```
def foo(something: false)
  bar if something  # => This is considered covered by builtin coverage,
                    #    even though `bar` might not even exist
end

# somewhere in a test:
foo
```

Optionally, branch coverage will detect if some branches are never taken. In the following example, `test_foo` only provides values for `x` that respond to `:to_s`, thus the implicit `else` is never tested (i.e. a value of `x` that does not respond to `:to_s`)

```
def foo(x)
  x = x.to_s if x.respond_to? :to_s
  # ...
end

def test_foo
  assert_equal something, foo(42)
  assert_equal something_else, foo(:hello)
end
```

## Examples

These examples are direct outputs from our HTML reporter:

* [Rails' `activesupport`](https://deep-cover.github.io/rails-cover/activesupport/)
* [Rails' `activerecord`](https://deep-cover.github.io/rails-cover/activerecord/)

## DeepCover vs builtin coverage

Feature            | MRI        | DeepCover
-------------------|:----------:|:--------:
Line coverage      |  partial   |  ✓
Statement coverage |  no        |  ✓
Branch coverage    |  partial   |  ✓
Method coverage    |  ✓         |  ~
Slowdown           |  < 1%      |  ~20%
Platform support   |  Ruby 2.5+ |  Ruby 2.1+, JRuby

**Line coverage**: MRI doesn't cover some lines (e.g. `when some_value`).

**Statement coverage**: MRI provides no way to tell which parts of any line is evaluated. DeepCover covers everything.

**Method coverage**: MRI considers every method defined, including methods defined on objects or via `define_method`, `class_eval`, etc. For Istanbul output, DeepCover has a different approach and covers all `def` and all blocks.

**Branch coverage**     | MRI | DeepCover
------------------------|:---:|:--------:
`if` / `unless` / `?:`  |  ✓  |    ✓
`case` / `when`         |  ✓  |    ✓
`❘❘` / `&&`             |  no |    ✓
`foo&.bar`              |  ✓  |    ✓
`{❘foo = 42, bar: 43❘}` |  no |    ✓
`while` / `until`       |  ✓  |    !

*Note on loops (!)*: DeepCover doesn't consider loops to be branches, but it's
easy to support it if needed.

## Installation

    gem install deep-cover

First we present the official way. There are also quick and dirty ways to try `deep-cover` without changing much your current setup, which we present afterwards.

### Canonical installation

*1* Add the `deep-cover` gem as a dependency:

For a standalone project (Rails app), add `deep-cover` to your Gemfile:

    gem 'deep-cover', '~> 0.4', group: :test, require: false

Then run `bundle`

For a gem, you want to add `spec.add_development_dependency 'deep-cover', '~> 0.4'` to your `gemspec` file instead.

*2* Require `deep-cover`

You must call `require 'deep-cover'` *before* the code you want to cover is loaded.

Typically, you want to insert that line in your `test/test_helper.rb` or `spec/spec_helper.rb` file at the right place. For example

```
ENV['RAILS_ENV'] ||= 'test'
require 'deep-cover' # Must be before the environment is loaded on the next line
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
# ...
```

*3* Create a config file (optional)

You may want to create a config file `.deep-cover.rb` at the root of your project, where you can set the config as you wish.

```
# File .deep-cover.rb
DeepCover.config do
  ignore :default_arguments
  # ...
end
```

*4* Launch it

Even after `DeepCover` is `require`d and configured, only a very minimal amount of code is actually loaded and coverage is *not started*.

The easiest way to actually start it is to use `deep-cover exec` instead of `bundle exec`.

For example:

```
$ deep-cover exec rspec
# ...all the output of rspec
# ...coverage report
```

### Command line interface (for a Rails app or a Gem):

An easy way to try `deep-cover`, without any configuration needed:

    deep-cover /path/to/rails/app/or/gem

This assumes your project has a `Gemfile`, and that your default `rake` task is set to execute all tests (otherwise set the `--command` option)

It also uses our builtin HTML reporter. Check the produced `coverage/index.html`.

### Projects using builtin Coverage (including SimpleCov) users

To make it easier to transition for projects already using the builtin `Coverage` library (or indirectly those using `SimpleCov`), there is a way to overwrite the `Coverage` library using `deep-cover`'s extended coverage.

Add to your Gemfile `gem 'deep-cover', require: false`, then run `bundle`.

Before you require `coverage` or `simplecov`, do a `require 'deep_cover/builtin_takeover'`.

For example, the `test/test_helper.rb` file for `simplecov` users will look like

```
require 'deep_cover/builtin_takeover'
require 'simplecov'
SimpleCov.start
# rest of `test_helper.rb`
```

## Usage

### Configuration

`configure` is used to specify how specific `DeepCover` should be and which files it should analyse. The following code reflects the default settings:

```
DeepCover.configure do
  ignore_uncovered :raise, :default_arguments
  detect_uncovered :trivial_if
  # TODO
  cover_paths %w[app lib]
end
```

The file `.deep-cover.rb` is loaded automatically when requiring `deep-cover` and is the best place to put the configuration.

*Note*: The configuration block is only executed when `deep-cover` is actually started.

#### Custom filters

`deep-cover` comes with a few filters that make it possible to ignore certain uncovered codes.

It is easy to add you own filters.

For example, if one wants to ignore uncovered calls to `raise` but the code uses `our_custom_raise` instead, the following with work:

```
DeepCover.configure do
  ignore_uncovered do
    type == :send &&
      receiver == nil &&
      message == :our_custom_raise
  end
end
```

## Development

After checking out the repo, run `bundle` then `rake dev:install` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

For detailed analysis:

`deep-cover -d -e "if(:try_me); puts 'cool'; end"`

To run one of the specs in `spec`:

`bin/cov boolean`

More details in the [contributing guide](https://github.com/deep-cover/deep-cover/blob/master/CONTRIBUTING.md).

### Status

Currently in development. *Alpha stage, API still subject to change*. Best time to get involved though ;-)

## Contributing

Please ask questions on StackOverflow.com. Maintainers monitor the tag `deep-cover.rb`.

Bug reports and pull requests are welcome on GitHub at https://github.com/deep-cover/deep-cover. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DeepCover project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/deep-cover/deep-cover/blob/master/CODE_OF_CONDUCT.md).

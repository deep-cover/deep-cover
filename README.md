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
Node coverage      |  no        |  ✓
Branch coverage    |  partial   |  ✓
Method coverage    |  ✓         |  ~
Slowdown           |  < 1%      |  ~20%
Platform support   |  Ruby 2.5+ |  Ruby 2.1+, JRuby

**Line coverage**: MRI doesn't cover some lines (e.g. `when some_value`).

**Node coverage**: MRI provides no way to tell which parts of any line is evaluated (e.g. `0.times { never_run }`). DeepCover covers everything.

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

Do the appropriate of the installation of the gem, then follow the steps that correspond to your situation.

    # if the project is a gem, add this to your .gemspec and then run `bundle install`
    spec.add_development_dependency 'deep-cover', '~> 0.7'

    # otherwise if using a Gemfile, add this to it and then run `bundle install`
    gem 'deep-cover', '~> 0.7', group: :test, require: false

    # otherwise just run:
    gem install deep-cover


### Trying `deep-cover` quickly

An easy way to try `deep-cover`, without any configuration needed:

    deep-cover clone command to run test
    # ex:
    deep-cover clone rake test

Check the produced `coverage/index.html`.

Note, this is a bit slower and may cause issues in your tests if your use relative paths that lead outside of the directory (Such as a dependency that is in a parent directory).

### Regular setup

1. Require `deep-cover`

    You must call `require 'deep-cover'` **before** the code you want to cover is loaded.

    Typically, you want to insert that line **at the very top** of `test/test_helper.rb` or `spec/spec_helper.rb` . If `deep-cover` is required after your code, then it won't be able to detect the coverage.

2. Create a config file (optional)

    You may want to create a config file `.deep-cover.rb` at the root of your project, where you can set the config as you wish.

    ```
    # File .deep-cover.rb
    DeepCover.config do
      ignore :default_arguments
      # ...
    end
    ```

3. Launch it

    Even after `DeepCover` is `require`d and configured, only a very minimal amount of code is actually loaded and coverage is *not started*.

    The easiest way to actually start it is to use `deep-cover exec`

    For example:

    ```
    $ deep-cover exec rspec
    # ...all the output of rspec
    # ...coverage report
    ```

### Already using SimpleCov / builtin Coverage

To make it easier to transition for projects already using the builtin `Coverage` library (such as those using `SimpleCov`), `deep-cover` can inject itself into those tools so that, while you still only have line-by-line coverage information, it becomes stricter, only marking a line as executed if *everything* on it has been executed.

You must call `require 'deep-cover/builtin_takeover'` **before** you require the coverage tool that you normally use.

For example, the `test/test_helper.rb` file for `SimpleCov` users will look like

```
require 'deep_cover/builtin_takeover'
require 'simplecov'
SimpleCov.start
# rest of `test_helper.rb`
```

Once this is done, simply generate the coverage as you normally would. In order to get detailed information about why a line is not covered, you will need to the regular `deep-cover` mode.

### Online coverage tools such as Code Climate, Coveralls, Codecov

At the moment, those tools do not support deep-cover. It is however possible to use the takeover system to, at least, make them stricter. Follow the explanation in the above section for injecting into `SimpleCov`.

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

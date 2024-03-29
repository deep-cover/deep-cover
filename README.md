[![Build Status](https://travis-ci.org/deep-cover/deep-cover.svg?branch=master)](https://travis-ci.org/deep-cover/deep-cover)
[![Backers on Open Collective](https://opencollective.com/deep-cover/backers/badge.svg)](#backers)
[![Sponsors on Open Collective](https://opencollective.com/deep-cover/sponsors/badge.svg)](#sponsors)

# Maintenance status

Deep Cover has not been updated for Ruby 3.x new syntax features, in particular:

- pattern match
- `{x:}` notation

Unfortunately, both co-authors are occupied contributing to other projects and can offer only minimal maintenance: complete PRs will be accepted and we welcome applications if you are interested in becoming a maintainer for this project.

# DeepCover

Deep Cover aims to be the best coverage tool for Ruby code:

- more accurate line coverage
- branch coverage
- can be used as a drop-in replacement for the built-in Coverage library.

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

- [Rails' `activesupport`](https://deep-cover.github.io/rails-cover/activesupport/)
- [Rails' `activerecord`](https://deep-cover.github.io/rails-cover/activerecord/)

## DeepCover vs builtin coverage

| Feature          |    MRI    |    DeepCover     |
| ---------------- | :-------: | :--------------: |
| Line coverage    |  partial  |        ✓         |
| Node coverage    |    no     |        ✓         |
| Branch coverage  |  partial  |        ✓         |
| Method coverage  |     ✓     |        ~         |
| Slowdown         |   < 1%    |       ~20%       |
| Platform support | Ruby 2.5+ | Ruby 2.1+, JRuby |

**Line coverage**: MRI doesn't cover some lines (e.g. `when some_value`).

**Node coverage**: MRI provides no way to tell which parts of any line is evaluated (e.g. `0.times { never_run }`). DeepCover covers everything.

**Method coverage**: MRI considers every method defined, including methods defined on objects or via `define_method`, `class_eval`, etc. For Istanbul output, DeepCover has a different approach and covers all `def` and all blocks.

| **Branch coverage**     | MRI | DeepCover |
| ----------------------- | :-: | :-------: |
| `if` / `unless` / `?:`  |  ✓  |     ✓     |
| `case` / `when`         |  ✓  |     ✓     |
| `❘❘` / `&&`             | no  |     ✓     |
| `foo&.bar`              |  ✓  |     ✓     |
| `{❘foo = 42, bar: 43❘}` | no  |     ✓     |
| `while` / `until`       |  ✓  |     !     |

_Note on loops (!)_: DeepCover doesn't consider loops to be branches, but it's
easy to support it if needed.

## Installation

Do the appropriate of the installation of the gem, then follow the steps that correspond to your situation.

    # if the project is a gem, add this to your .gemspec and then run `bundle install`
    spec.add_development_dependency 'deep-cover', '~> 0.7'

    # otherwise if using a Gemfile, add this to it and then run `bundle install`
    gem 'deep-cover', '~> 0.7', group: :test

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

   Note that if some of your tests run by launching another process, that process will have to `require 'deep-cover'` also. For example you could insert `require 'deep-cover' if ENV['DEEP_COVER']` at the beginning of `lib/my_awesome_gem.rb`, before all the `require_relative 'my_awesome_gem/fabulous_core_part_1'`, ...
   Note that the environment variable `DEEP_COVER` is set by `deep-cover exec` or `DeepCover.start`.

2. Create a config file (optional)

   You may want to create a config file `.deep_cover.rb` at the root of your project, where you can set the config as you wish.

   ```
   # File .deep_cover.rb
   DeepCover.configure do
     ignore_uncovered :default_argument
     # ...
   end
   ```

3. Launch it

   Even after `DeepCover` is `require`d and configured, only a very minimal amount of code is actually loaded and coverage is _not started_.

   The easiest way to actually start it is to use `deep-cover exec`

   For example:

   ```
   $ deep-cover exec rspec
   # ...all the output of rspec
   # ...coverage report
   ```

### Already using SimpleCov / builtin Coverage

To make it easier to transition for projects already using the builtin `Coverage` library (such as those using `SimpleCov`), `deep-cover` can inject itself into those tools so that, while you still only have line-by-line coverage information, it becomes stricter, only marking a line as executed if _everything_ on it has been executed.

You must call `require 'deep_cover/builtin_takeover'` **before** you require the coverage tool that you normally use.

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
  ignore_uncovered :raise, :default_argument
  detect_uncovered :trivial_if
  paths %w[app lib]
  exclude_paths ['fixtures', /^lib\/ignore/]
end
```

The file `.deep_cover.rb` is loaded automatically when requiring `deep-cover` and is the best place to put the configuration.

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

## Contributing

Please ask questions on StackOverflow.com. Maintainers monitor the tag `deep-cover.rb`.

Bug reports and pull requests are welcome on GitHub at https://github.com/deep-cover/deep-cover. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Contributors

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)].
<a href="https://github.com/deep-cover/deep-cover/graphs/contributors"><img src="https://opencollective.com/deep-cover/contributors.svg?width=890&button=false" /></a>

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DeepCover project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/deep-cover/deep-cover/blob/master/CODE_OF_CONDUCT.md).

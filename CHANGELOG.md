# Changelog

* We now officially support JRuby. Our test-suite passes with it.

## 0.7.0

* Switched CLI to rely on Thor instead of Slop
* Added lower-level CLI commands: gather, merge, report, clear
* Added `deep-cover clone`, it does what `deep-cover` without commands did.
* Changed the default when using `deep-cover` without commands, it now shows a short help.
  Use `deep-cover clone` to reproduce the previous default.
* `deep-cover exec` now uses the same default command as `deep-cover clone`
* Added global option -C (--change-directory) which basically executes a `cd` before executing deep-cover.
  This replaces the default path parameter of `deep-cover clone`
* `deep-cover clone` now receives an optional command as positional argument, just like `deep-cover exec`.
  It's previous positional argument (path to run) is now the -C option.
* `deep-cover` now display coverage information for files that were not loaded. This may lower your the coverage results.
* The configuration for the paths to cover can now receive globs.
* `deep-cover clone` no longer needs bundler. It still uses a Gemfile, if it finds one, to decide between
  copying the current directory or the parent one.
* `deep-cover clone` is more efficient and has less edge cases that would make some files not be covered.

## 0.6.3

* Split the gem into two: `deep-cover` and `deep-cover-core`.
  `deep-cover` is the cli, and depends on `deep-cover-core`, so nothing special is needed.
  Those that don't want to have the CLI (either for dependencies or because they don't use it)
  may now avoid it.

## 0.6.2

* `#require` is much faster in MRI Ruby 2.1 and 2.2, resulting in much faster boot time for most applications when deep-cover is enabled.

## 0.6.1

* Takeover now also considers branch coverage to generate the per-line output.
  In order to reach 100% coverage with takeover, you need 100% node coverage and 100% branch coverage.
* Support for covering of `#load` in MRI Ruby 2.1 and 2.2

## 0.6

* Support for covering of `#load` in MRI Ruby 2.3+

## 0.5

* Added custom filters

## 0.4

* Added `deep-cover exec`
* Automatic loading of `.deep-cover.rb`
* Support for `# nocov`

## 0.3

* Text reporter
* Lazy loading

## 0.2

* HTML reporter
* Improved analyser

## 0.1

* Initial "proof of concept" release

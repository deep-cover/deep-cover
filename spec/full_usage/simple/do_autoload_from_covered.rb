# frozen_string_literal: true
$executed_files << File.basename(__FILE__)

autoload :AutoloadedFromCovered, 'autoloaded_from_covered'
_foo = ::AutoloadedFromCovered

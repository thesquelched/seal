#!/usr/bin/env ruby

require './lib/seal'

raise ArgumentError, 'Usage: seal.rb <organization> [<team> ...]' if ARGV.empty?
Seal.new(ARGV[0], ARGV.drop(1)).bark

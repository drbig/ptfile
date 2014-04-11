#!/usr/bin/env ruby
# coding: utf-8
# vim: ts=2 et sw=2 sts=2
#
# small/ptfile/examples/inspect.rb - Inspect a set of module files
# 
# Copyright © 2014 Piotr S. Staszewski 
# Visit http://www.drbig.one.pl for contact information.
#

require 'ptfile'

processed = 0
errors = 0

ARGV.each do |path|
  puts "   FILE: #{path}"
  begin
    mod = File.open(path) {|f| PTFile.read(f) }
  rescue IOError
    puts "  ERROR: IO error, please investigate or report"
    errors += 1
  else
    if mod.sane?
      puts "  TITLE: #{mod.title}"
      puts "SAMPLES: #{mod.samples_count}/#{mod.sample_table.length}"
      mod.sample_table.each_with_index do |s,i|
        puts "     #{(i+1).to_s.rjust(2)}: \"#{s[:name].ljust(22)}\""
      end
      processed += 1
    else
      puts "  ERROR: File seems broken, please investigate or report"
      errors += 1
    end
  end
  print "\n"
end

puts "OK: #{processed}, ERROR: #{errors}, TOTAL #{processed + errors}"

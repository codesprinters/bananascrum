#!/usr/bin/env ruby

# Add ruby standard libraries to load path
$: << File.join('META-INF', 'jruby.home', 'lib', 'ruby', 'site_ruby', '1.8')
# Add custom gem dependencies
$: << File.join('vendor', 'gems', 'json-1.2.0', 'lib')
$: << File.join('vendor', 'gems', 'eventmachine-0.12.10-java', 'lib')
$: << File.join('vendor', 'gems', 'eventmachine-0.12.10-java', 'ext')
require File.join('vendor', 'gems', 'juggernaut-0.5.8', 'lib', 'juggernaut')

Juggernaut::Runner.run

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redisrank/version"

Gem::Specification.new do |s|
  s.name        = "redisrank"
  s.version     = Redisrank::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Felipe Lopes"]
  s.email       = ["felipelopes10@gmail.com"]
  s.homepage    = "http://github.com/felipeclopes/redisrank"
  s.summary     = %q{A Redis-backed ranking storage and querying library written in Ruby.}
  s.description = %q{A Redis-backed ranking storage and querying library written in Ruby.}

  s.rubyforge_project = "redisrank"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport', '>= 2.3.6'
  s.add_runtime_dependency 'json', '>= 1.4.0'
  s.add_runtime_dependency 'redis', '>= 2.1.0'
  s.add_runtime_dependency 'time_ext', '>= 0.2.9'

  s.add_development_dependency 'rake', '>= 0.8.7'
  s.add_development_dependency 'rspec', '>= 2.1.0'
  s.add_development_dependency 'yard', '>= 0.6.3'
  s.add_development_dependency 'simplecov', '>= 0.6.1'
end

# -*- encoding: utf-8 -*-
require File.expand_path('../lib/bugflow/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'bugflow'
  gem.version     = BugFlow::VERSION.dup
  gem.author      = 'Buras Arkadiusz'
  gem.email       = 'macbury@gmail.com'
  gem.homepage    = 'http://bugflow.herokuapp.com/'
  gem.summary     = %q{Send your application errors to our hosted service and reclaim your inbox.}
  gem.description = %q{Send your application errors to our hosted service and reclaim your inbox.}

  gem.files         = `git ls-files`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'eventmachine'
  gem.add_runtime_dependency 'amqp'
end
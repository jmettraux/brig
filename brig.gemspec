# encoding: utf-8

require File.join(File.dirname(__FILE__), 'lib/brig/version')
  # bundler wants absolute path


Gem::Specification.new do |s|

  s.name = 'brig'
  s.version = Brig::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'http://lambda.io'
  s.rubyforge_project = 'ruote'
  s.summary = 'creating chroot jails and running stuff in them'
  s.description = %{
Creating chroot jails and running stuff in them.

(Warning: defense is something better done in depth, and chroot was never meant as a security tool)
  }

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md', '*.mdown'
  ]

  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'yajl-ruby'
  s.add_runtime_dependency 'rufus-json', '>= 1.0.1'

  s.add_development_dependency 'rspec'

  s.require_path = 'lib'

  # TODO : bin/ stuff ?
end


# coding: utf-8
require './lib/gitpeer/version'

Gem::Specification.new do |spec|
  spec.name          = "gitpeer"
  spec.version       = GitPeer::VERSION
  spec.authors       = ["Andrey Popp"]
  spec.email         = ["8mayday@gmail.com"]
  spec.description   = %q{Expose your git repository as an API}
  spec.summary       = %q{Expose your git repository as an API}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "scorched", ">= 0.16"
  spec.add_dependency "uri_template", "~> 0.5"
  spec.add_dependency "rugged", "~> 0.19"
  spec.add_dependency "omniauth", "~> 1.1.4"
  spec.add_dependency "omniauth-github", "~> 1.1.1"
  spec.add_dependency "sqlite3", "~> 1.3.7"
  spec.add_dependency "sequel", "~> 4.0.0"
  spec.add_dependency "thin", "~> 1.5.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "racksh"
  spec.add_development_dependency "rspec", "~> 1.3"
  spec.add_development_dependency "rerun", "~> 0.8"
end

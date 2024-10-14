# frozen_string_literal: true

require_relative "lib/light_tr/version"

Gem::Specification.new do |spec|
  spec.name          = "light_tr"
  spec.version       = LightTr::VERSION
  spec.authors       = ["Paweł Niemczyk"]
  spec.email         = ["pawel@way2do.it"]

  spec.summary       = "Translate any word via Google Translate API"
  spec.description   = "Translate any word via Google Translate API"
  spec.homepage      = "https://github.com/pniemczyk/light_tr"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/pniemczyk/light_tr"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'rspec', '~> 2.12'
  spec.add_development_dependency 'guard-rspec', '~> 0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_dependency 'faraday-mashify', '~> 0.1'
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'hashie', '~> 2.1'
  spec.add_dependency 'executable', '~> 1.2'
  spec.add_dependency 'awesome_print', '~> 1.2'
  spec.add_dependency 'lockbox', '~> 0.6'
end

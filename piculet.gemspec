# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'piculet/version'

Gem::Specification.new do |spec|
  spec.name          = "piculet"
  spec.version       = Piculet::VERSION
  spec.authors       = ["winebarrel"]
  spec.email         = ["sgwr_dts@yahoo.co.jp"]
  spec.description   = "Piculet is a tool to manage EC2 Security Group. It defines the state of EC2 Security Group using DSL, and updates EC2 Security Group according to DSL."
  spec.summary       = "Piculet is a tool to manage EC2 Security Group."
  spec.homepage      = "http://piculet.codenize.tools/"
  spec.license       = "MIT"
  spec.files         = %w(README.md) + Dir.glob('bin/**/*') + Dir.glob('lib/**/*')

  spec.add_dependency "aws-sdk-v1", ">= 1.48.0"
  spec.add_dependency "term-ansicolor", ">= 1.2.2"
  spec.add_dependency "diffy"
  spec.add_dependency "hashie"

  #spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  #spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.4.0"
  spec.add_development_dependency "rspec-instafail"
end

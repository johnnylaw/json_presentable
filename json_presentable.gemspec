$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "json_presentable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "json_presentable"
  s.version     = JsonPresentable::VERSION
  s.authors     = ["John Lawrence"]
  s.email       = ["johnonrails@gmail.com"]
  s.homepage    = "http://github.com/johnnylaw/json_presentable"
  s.summary     = "For presenting JSON from controllers in a Rails app"
  s.description = "Presenters that make it easy for you to display your resources as JSON. An easy API allows you to configure the presentation of each resource in different contexts."
  s.license     = 'MIT'

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.0.0"
  s.add_dependency 'sourcify'

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "pry"
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'database_cleaner', '~> 1.0.0'
  s.add_development_dependency "slim"
  s.add_development_dependency "coveralls"

  s.test_files = Dir["spec/**/*"]
end

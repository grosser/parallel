$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
name = "soft_deletion"
require "#{name}/version"

Gem::Specification.new name, SoftDeletion::VERSION do |s|
  s.summary = "Explicit soft deletion for ActiveRecord via deleted_at and default scope."
  s.authors = ["ZenDesk"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.license = 'MIT'
end

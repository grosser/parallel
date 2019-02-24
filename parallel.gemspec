name = "parallel"
$LOAD_PATH << File.expand_path('../lib', __FILE__)
require "#{name}/version"

Gem::Specification.new name, Parallel::VERSION do |s|
  s.summary = "Run any kind of code in parallel processes"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib MIT-LICENSE.txt`.split("\n")
  s.license = "MIT"
  s.required_ruby_version = '>= 2.2'
end

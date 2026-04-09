# frozen_string_literal: true
name = "parallel"
$LOAD_PATH << File.expand_path('lib', __dir__)
require "#{name}/version"

Gem::Specification.new name, Parallel::VERSION do |s|
  s.summary = "Run any kind of code in parallel processes"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.metadata = {
    "bug_tracker_uri" => "#{s.homepage}/issues",
    "documentation_uri" => "#{s.homepage}/blob/v#{s.version}/Readme.md",
    "source_code_uri" => "#{s.homepage}/tree/v#{s.version}",
    "wiki_uri" => "#{s.homepage}/wiki",
    "changelog_uri" => "#{s.homepage}/blob/v#{s.version}/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }
  s.files = `git ls-files lib MIT-LICENSE.txt`.split("\n")
  s.license = "MIT"
  s.required_ruby_version = '>= 3.3'
end

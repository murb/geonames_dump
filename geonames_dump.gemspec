require File.expand_path("../lib/geonames/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors = ["Alex Pooley", "Thomas Kienlen"]
  gem.email = ["thomas.kienlen@lafourmi-immo.com"]
  gem.description = "GeonamesDump import geographic data from geonames project into your application, avoiding to use external service like Google Maps."
  gem.summary = "Import data from Geonames"
  gem.homepage = "https://github.com/kmmndr/geonames_dump"

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.name = "geonames_dump"
  gem.require_paths = ["lib"]
  gem.version = Geonames::VERSION
  gem.add_runtime_dependency "ruby-progressbar"
  gem.add_runtime_dependency "activerecord-reset-pk-sequence"
  gem.add_runtime_dependency "rubyzip", "~>2.3"
  gem.add_development_dependency "minitest", "~>5.0"
  gem.add_development_dependency "rake", ">10.0"
end

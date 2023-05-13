namespace :geonames do
  desc 'Truncate and install most of geonames data (country, admin1, admin2, cities15000)'
  task :install => ['truncate:all', 'import:many']
end

require 'net/http'
require 'ruby-progressbar'
require 'activerecord-reset-pk-sequence'

namespace :geonames_dump do
  namespace :truncate do

    desc 'Truncate all geonames data.'
    #task :all => [:countries, :cities, :admin1, :admin2]
    task :all => [:countries, :features]

    def truncate_table(klass)
      if ActiveRecord::Base.connection.adapter_name == "Mysql2"
        klass.connection.truncate(klass.table_name)
      else
        klass.delete_all && klass.reset_pk_sequence
      end
    end

    desc 'Truncate admin1 codes'
    task :admin1 => :environment do
      truncate_table(Geonames::Admin1)
    end

    desc 'Truncate admin2 codes'
    task :admin2 => :environment do
      truncate_table(Geonames::Admin2)
    end

    desc 'Truncate cities informations'
    task :cities => :environment do
      truncate_table(Geonames::City)
    end

    desc 'Truncate countries informations'
    task :countries => :environment do
      truncate_table(Geonames::Country)
    end

    desc 'Truncate features informations'
    task :features => :environment do
      truncate_table(Geonames::Feature)
    end

    desc 'Truncate alternate names'
    task :alternate_names => :environment do
      truncate_table(Geonames::AlternateName)
    end
  end
end

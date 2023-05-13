require "net/http"
require "ruby-progressbar"
require "zip"
require "geonames"

root = defined?(Rails) ? Rails.root : Pathname.new(File.dirname(__FILE__)).join("..", "..")
CACHE_DIR = root.join("db", "geonames_cache")

GEONAMES_FEATURES_COL_NAME = [
  :id, :name, :asciiname, :alternatenames, :latitude, :longitude,
  :feature_class, :feature_code, :country_code, :cc2, :admin1_code,
  :admin2_code, :admin3_code, :admin4_code, :population, :elevation,
  :dem, :timezone, :modification
]
GEONAMES_ALTERNATE_NAMES_COL_NAME = [
  :alternate_name_id, :geonameid, :isolanguage, :alternate_name,
  :is_preferred_name, :is_short_name, :is_colloquial, :is_historic
]
GEONAMES_COUNTRIES_COL_NAME = [
  :iso, :iso3, :iso_numeric, :fips, :country, :capital, :area, :population, :continent,
  :tld, :currency_code, :currency_name, :phone, :postal_code_format, :postal_code_regex,
  :languages, :geonameid, :neighbours, :equivalent_fips_code
]
GEONAMES_ADMINS_COL_NAME = [
  :code, :name, :asciiname, :id
]

GEONAMES_HIERARCHY = [
  :parentId, :childId, :geo_type
]

namespace :geonames do
  namespace :import do
    desc "Prepare everything to import data"
    task :prepare do
      begin
        Dir.mkdir(CACHE_DIR)
      rescue
        nil
      end
      FileUtils.mkdir_p File.join(CACHE_DIR, "alternatenames")

      disable_logger
      disable_validations if ENV["SKIP_VALIDATION"]
    end

    desc "Import ALL geonames data."
    task all: [:many, :features]

    desc "Import most of geonames data. Recommended after a clean install."
    task many: [:prepare, :countries, :cities15000, :admin1, :admin2]

    desc "Import all cities, regardless of population."
    task cities: [:prepare, :cities15000, :cities5000, :cities1000]

    desc "Import feature data. Specify Country ISO code (example : COUNTRY=FR) for just a single country. NOTE: This task can take a long time!"
    task features: [:prepare, :environment] do
      download_file = ENV["COUNTRY"].present? ? ENV["COUNTRY"].upcase : "allCountries"
      txt_file = get_or_download("http://download.geonames.org/export/dump/#{download_file}.zip")

      # Import into the database.
      File.open(txt_file) do |f|
        # TODO: add feature selection
        insert_data(f, GEONAMES_FEATURES_COL_NAME, Geonames::City, title: "Features", primary_key: :id)
      end
    end

    # geonames:import:citiesNNN where NNN is population size.
    %w[15000 5000 1000 500].each do |population|
      desc "Import cities with population greater than #{population}"
      task "cities#{population}".to_sym => [:prepare, :environment] do
        txt_file = get_or_download("http://download.geonames.org/export/dump/cities#{population}.zip")

        File.open(txt_file) do |f|
          insert_data(f, GEONAMES_FEATURES_COL_NAME, Geonames::City, title: "cities of #{population}", primary_key: :id)
        end
      end
    end

    desc "Import countries informations"
    task countries: [:prepare, :environment] do
      txt_file = get_or_download("http://download.geonames.org/export/dump/countryInfo.txt")

      File.open(txt_file) do |f|
        insert_data(f, GEONAMES_COUNTRIES_COL_NAME, Geonames::Country, title: "Countries")
      end
    end

    desc "Import alternate names"
    task alternate_names: [:prepare, :environment] do
      download_file = ENV["ALTERNATE_NAMES_LANG"].present? ? "alternatenames/#{ENV["ALTERNATE_NAMES_LANG"].upcase}" : "alternateNames"

      txt_file = get_or_download("http://download.geonames.org/export/dump/#{download_file}.zip",
        txt_file: "#{download_file}.txt",
        zip_file: "#{download_file}.zip")

      File.open(txt_file) do |f|
        insert_data(f,
          GEONAMES_ALTERNATE_NAMES_COL_NAME,
          Geonames::AlternateName,
          title: "Alternate names",
          buffer: 10000,
          primary_key: [:alternate_name_id, :geonameid])
      end
    end

    desc "Import iso language codes"
    task language_codes: [:prepare, :environment] do
      txt_file = get_or_download("http://download.geonames.org/export/dump/alternateNames.zip",
        txt_file: "iso-languagecodes.txt")

      File.open(txt_file) do |f|
        insert_data(f, GEONAMES_COUNTRIES_COL_NAME, Geonames::Country, title: "Countries")
      end
    end

    desc "Import admin1 codes"
    task admin1: [:prepare, :environment] do
      txt_file = get_or_download("http://download.geonames.org/export/dump/admin1CodesASCII.txt")

      File.open(txt_file) do |f|
        insert_data(f, GEONAMES_ADMINS_COL_NAME, Geonames::Admin1, title: "Admin1 subdivisions", primary_key: :id) do |klass, attributes, col_value, idx|
          col_value.gsub!("(general)", "")
          col_value.strip!
          if idx == 0
            country, admin1 = col_value.split(".")
            attributes[:country_code] = country.strip
            attributes[:admin1_code] = begin
              admin1.strip
            rescue
              nil
            end
          else
            attributes[GEONAMES_ADMINS_COL_NAME[idx]] = col_value
          end
        end
      end
    end

    desc "Import admin2 codes"
    task admin2: [:prepare, :environment] do
      txt_file = get_or_download("http://download.geonames.org/export/dump/admin2Codes.txt")

      File.open(txt_file) do |f|
        insert_data(f, GEONAMES_ADMINS_COL_NAME, Geonames::Admin2, title: "Admin2 subdivisions", primary_key: :id) do |klass, attributes, col_value, idx|
          col_value.gsub!("(general)", "")
          if idx == 0
            country, admin1, admin2 = col_value.split(".")
            attributes[:country_code] = country.strip
            attributes[:admin1_code] = admin1.strip # rescue nil
            attributes[:admin2_code] = admin2.strip # rescue nil
          else
            attributes[GEONAMES_ADMINS_COL_NAME[idx]] = col_value
          end
        end
      end
    end

    desc "Import hierarchy"
    task hierarchy: [:prepare, :environment] do
      txt_file = get_or_download("http://download.geonames.org/export/dump/hierarchy.zip", txt_file: "hierarchy.txt")
      File.open(txt_file) do |f|
        insert_data(f, GEONAMES_HIERARCHY, Geonames::Hierarchy, title: "hierarchy")
      end
    end

    private

    def disable_logger
      ActiveRecord::Base.logger = Logger.new((RUBY_PLATFORM != "i386-mingw32") ? "/dev/null" : "NUL")
    end

    def disable_validations
      ActiveRecord::Base.reset_callbacks(:validate)
    end

    def get_or_download(url, options = {})
      filename = File.basename(url)
      cache_dir = /alternatenames/.match?(url) ? CACHE_DIR : File.join(CACHE_DIR, "alternatenames")
      unzip = File.extname(filename) == ".zip"
      txt_filename = unzip ? "#{File.basename(filename, ".zip")}.txt" : filename
      txt_file_in_cache = File.join(cache_dir, options[:txt_file] || txt_filename)
      zip_file_in_cache = File.join(cache_dir, options[:zip_file] || filename)

      if File.exist?(txt_file_in_cache)
        puts "File already exists in cache : #{txt_file_in_cache}"
      else
        puts "File doesn't exist in cache : #{txt_file_in_cache}"
        if unzip
          download(url, zip_file_in_cache)
          unzip_file(zip_file_in_cache, cache_dir)
        else
          download(url, txt_file_in_cache)
        end
      end

      (File.exist?(txt_file_in_cache) ? txt_file_in_cache : nil)
    end

    def unzip_file(file, destination)
      puts "Unzipping #{file}"
      Zip::File.open(file) do |zip_file|
        zip_file.each do |f|
          f_path = File.join(destination, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        end
      end
    end

    def download(url, output)
      File.open(output, "wb") do |file|
        body = fetch(url)
        puts "Writing #{url} to #{output}"
        file.write(body)
      end
    end

    def fetch(url)
      puts "Fetching #{url}"
      url = URI.parse(url)
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
      res.body
    end

    def insert_data(file_fd, col_names, main_klass = Geonames::Feature, options = {}, &block)
      # Setup nice progress output.
      file_size = file_fd.stat.size
      title = options[:title] || "Feature Import"
      buffer = options[:buffer] || 1000
      primary_key = options[:primary_key] || :geonameid
      progress_bar = ProgressBar.create(title: title, total: file_size, format: "%a |%b>%i| %p%% %t")

      # create block array
      blocks = Geonames::Blocks.new
      line_counter = 0

      file_fd.each_line do |line|
        # prepare data
        attributes = {}
        klass = main_klass

        # skip comments
        next if line.start_with?("#")

        line_counter += 1

        # read values
        line.strip.split("\t").each_with_index do |col_value, idx|
          col = col_names[idx]

          # skip leading and trailing whitespace
          col_value.strip!

          # block may change the type of object to create
          if block
            yield klass, attributes, col_value, idx
          else
            attributes[col] = col_value
          end
        end

        # create or update object
        # if filter?(attributes) && (block && block.call(attributes))
        blocks.add_block do
          primary_keys = primary_key.is_a?(Array) ? primary_key : [primary_key]
          if primary_keys.all? { |key| attributes.include?(key) }
            if ENV["QUICK"]
              klass.create(attributes)
            else
              where_condition = {}
              primary_keys.each do |key|
                where_condition[key] = attributes[key]
              end
              object = klass.where(where_condition).first_or_initialize
              object.update(attributes)
              object.save if object.new_record? || object.changed?
            end
          else
            klass.create(attributes)
          end
        end

        # increase import speed by performing insert using transaction
        if line_counter % buffer == 0
          ActiveRecord::Base.transaction do
            blocks.call_and_reset
          end
          line_counter = 0
        end

        # move progress bar
        progress_bar.progress = file_fd.pos
      end

      unless blocks.empty?
        ActiveRecord::Base.transaction do
          blocks.call_and_reset
        end
      end
    end

    # Return true when either:
    #  no filter keys apply.
    #  all applicable filter keys include the filter value.
    def filter?(attributes)
      attributes.keys.all? { |key| filter_keyvalue?(key, attributes[key]) }
    end

    def filter_keyvalue?(col, col_value)
      return true unless ENV[col.to_s]
      ENV[col.to_s].split("|").include?(col_value.to_s)
    end
  end
end

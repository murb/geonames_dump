require "minitest/autorun"
require "rake"
require "fileutils"
require "logger"

load File.join(File.dirname(__FILE__), "/mock_rails_tasks.rake")
Dir[File.join(File.dirname(__FILE__), "../../../lib/tasks/*.rake")].each { |f| load f }

root = Pathname.new(File.dirname(__FILE__)).join("..", "..", "..")

puts "test root: #{root}"

FileUtils.rm_rf(File.join(root, "db"))

# from https://gist.github.com/jazzytomato/79bb6ff516d93486df4e14169f4426af
def mock_env(partial_env_hash)
  old = ENV.to_hash
  ENV.update partial_env_hash
  begin
    yield
  ensure
    ENV.replace old
  end
end

class Minitest::Parallel::Executor
  def size
    1
  end
end

# mock ActiveRecord
class ActiveRecord::Base
  class << self
    attr_accessor :transaction
    attr_accessor :logger

    def reset_callbacks param
    end
  end
end

class Geonames::City < ActiveRecord::Base
end

class Geonames::AlternateName < ActiveRecord::Base
end

class Geonames::Country < ActiveRecord::Base
end

class FakeResponse
  UnexpectedRequest = Class.new(StandardError)
  attr_accessor :expect_path

  def initialize(file)
    @file = file
  end

  def body
    File.binread(@file)
  end

  def request url
    if @expect_path
      if @expect_path.to_s != url.path
        raise UnexpectedRequest.new("#{@expect_path} != #{url.path}")
      end
    end
  end
end

describe "rake geonames:import" do
  describe ":prepare" do
    it "should set up the directory structure" do
      Minitest::Test.io_lock.synchronize do
        root = Pathname.new(File.dirname(__FILE__)).join("..", "..", "..")

        # FileUtils.rm_rf(File.join(root, 'db'))
        Rake::Task["geonames:import:prepare"].invoke

        _(File.directory?(File.join(root, "db"))).must_equal true
        _(File.directory?(File.join(root, "db/geonames_cache"))).must_equal true
        _(File.directory?(File.join(root, "db/geonames_cache/alternatenames"))).must_equal true

        # FileUtils.rm_rf(File.join(root, 'db'))
      end
    end
  end

  describe ":cities15000" do
    it "should download the files" do
      Rake::Task["geonames:import:prepare"].invoke

      stubbed_response = FakeResponse.new(File.join(File.dirname(__FILE__), "../../fixtures", "cities15000.zip"))

      Net::HTTP.stub(:start, stubbed_response, stubbed_response) do
        Rake::Task["geonames:import:cities15000"].invoke
      end
    end
  end

  describe ":alternate_names" do
    it "should download alternateNames.zip by default" do
      Rake::Task["geonames:import:prepare"].invoke

      stubbed_response = FakeResponse.new(File.join(File.dirname(__FILE__), "../../fixtures", "alternateNames.zip"))
      stubbed_response.expect_path = "/export/dump/alternateNames.zip"
      Minitest::Test.io_lock.synchronize do
        Net::HTTP.stub(:start, stubbed_response, stubbed_response) do
          mock_env "ALTERNATE_NAMES_LANG" => nil do
            Rake::Task["geonames:import:alternate_names"].invoke
          end
        end
      end
    end

    it "should download localized alternateNames" do
      Rake::Task["geonames:import:prepare"].invoke
      stubbed_response = FakeResponse.new(File.join(File.dirname(__FILE__), "../../fixtures", "alternatenames/NL.zip"))
      stubbed_response.expect_path = "/export/dump/alternatenames/NL.zip"

      Minitest::Test.io_lock.synchronize do
        Net::HTTP.stub(:start, stubbed_response, stubbed_response) do
          mock_env "ALTERNATE_NAMES_LANG" => "NL" do
            Rake::Task["geonames:import:alternate_names"].invoke
          end
        end
      end
    end
  end

  describe ":language_codes" do
    it "should extract the right file" do
      Rake::Task["geonames:import:prepare"].invoke

      stubbed_response = FakeResponse.new(File.join(File.dirname(__FILE__), "../../fixtures", "alternateNames.zip"))
      stubbed_response.expect_path = "/export/dump/alternateNames.zip"
      Minitest::Test.io_lock.synchronize do
        Net::HTTP.stub(:start, stubbed_response, stubbed_response) do
          mock_env "ALTERNATE_NAMES_LANG" => nil do
            Rake::Task["geonames:import:language_codes"].invoke
          end
        end
      end
    end
  end
end

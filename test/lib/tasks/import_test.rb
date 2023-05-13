require "minitest/autorun"
require "rake"
require "fileutils"
require "logger"

load File.join(File.dirname(__FILE__), "/mock_rails_tasks.rake")
Dir[File.join(File.dirname(__FILE__), "../../../lib/tasks/*.rake")].each { |f| load f }

root = Pathname.new(File.dirname(__FILE__)).join("..", "..", "..")
FileUtils.rm_rf(File.join(root, "db"))

# mock ActiveRecord
class ActiveRecord::Base
  class << self
    def logger= something
    end

    def reset_callbacks param
    end

    def transaction
    end
  end
end

class Geonames::City
  class << self
    def transaction
    end
  end
end

class FakeResponse
  UnexpectedRequest = Class.new(StandardError)
  def initialize(file)
    @file = file
  end

  def body
    File.binread(@file)
  end

  def expect_path url
    @expect_path = url
  end

  def request url
    if @expect_path
      if @expect_path.to_s != url.path
        UnexpectedRequest.new("#{@expect_path.to_s} != #{url.path}")
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

      stubbed_response = FakeResponse.new(File.join(File.dirname(__FILE__), "../../fixtures", "cities15000.zip"))
      stubbed_response.expect_path("/export/dump/alternateNames.zip")

      Net::HTTP.stub(:start, stubbed_response, stubbed_response) do
        Rake::Task["geonames:import:alternate_names"].invoke
      end

    end
  end
end

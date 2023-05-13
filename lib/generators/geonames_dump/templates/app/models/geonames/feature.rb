class Geonames::Feature < ActiveRecord::Base
  self.table_name = "geonames_features"

  # validates_uniqueness_of :geonameid
  before_save :set_asciiname_first_letters

  has_many :geonames_alternate_names,
    inverse_of: :geonames_feature,
    foreign_key: "geonameid",
    class_name: "Geonames::AlternateName"

  alias_method :alternate_names, :geonames_alternate_names

  ##
  # Search for feature, searches might include country (separated by ',')
  #
  scope :search, lambda { |query|
    virgule = query.include? ","

    splited = virgule ? query.split(",") : [query]

    country = virgule ? splited.last.strip : nil

    queries = virgule ? splited[0...-1] : splited
    queries = queries.join(" ").split(" ")

    ret = by_name(*queries)

    unless country.nil?
      geonames_country = Geonames::Country.search(country).first
      ret = ret.where(country_code: geonames_country.iso) unless geonames_country.nil?
    end

    ret
  }

  ##
  # Find by names
  #
  scope :by_name, lambda { |*queries|
    ret = self
    queries.collect.with_index do |q, idx|
      query = (idx == 0) ? q.to_s : "%#{q}%"
      ret = ret.where("asciiname_first_letters = ?", q[0...3].downcase)
      ret = ret.where("name LIKE ? or asciiname LIKE ?", query, query)
    end
    ret
  }

  protected

  ##
  # Set first letters of name into index column
  #
  def set_asciiname_first_letters
    self.asciiname_first_letters = asciiname[0...3].downcase unless asciiname.nil?
  end
end

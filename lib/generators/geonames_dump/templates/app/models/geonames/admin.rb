class Geonames::Admin < ActiveRecord::Base
  self.table_name = "geonames_admins"

  before_save :set_asciiname_first_letters

  def code=(value)
    self.country_code, self.admin1_code, self.admin2_code = value.split(".")
  end

  def code
    [country_code, admin1_code, admin2_code].compact.join(".")
  end

  private

  def set_asciiname_first_letters
    self.asciiname_first_letters = asciiname[0...3].downcase unless asciiname.nil?
  end
end

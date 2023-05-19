class CreateGeonamesAdmins < ActiveRecord::Migration[6.0]
  # http://download.geonames.org/export/dump/readme.txt
  # code      : iso country codes, 2 characters, admin1, admin2
  # name      : name of geographical point (utf8) varchar(200)
  # asciiname : name of geographical point in plain ascii characters, varchar(200)
  # id:       : (geonameid integer id of record in geonames database)
  def change
    create_table :geonames_admins do |t|
      t.string :name, length: 200
      t.string :asciiname, length: 200
      t.string :country_code, length: 2
      t.string :admin1_code, length: 20
      t.string :admin2_code, length: 80

      t.string :type
      t.string :asciiname_first_letters

      t.timestamps
    end

    # add_index :geonames_admins, :geonameid
    add_index :geonames_admins, :name, length: 20
    add_index :geonames_admins, :asciiname, length: 20
    add_index :geonames_admins, :country_code, length: 20
    add_index :geonames_admins, :admin1_code, length: 20
    add_index :geonames_admins, :admin2_code, length: 20
    add_index :geonames_admins, :type, length: 20
    add_index :geonames_admins, :asciiname_first_letters, length: 3
  end
end

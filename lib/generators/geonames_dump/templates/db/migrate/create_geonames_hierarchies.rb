#  parentId, childId, type
class CreateGeonamesHierarchies < ActiveRecord::Migration
  def change
    create_table :geonames_hierarchies do |t|
      t.integer :parentId
      t.integer :childId
      t.string :geo_type
      t.timestamps
    end
  end
end

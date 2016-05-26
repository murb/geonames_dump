#  parentId, childId, type
class CreateGeonamesHierarchies < ActiveRecord::Migration
  def change
    create_table :geonames_hierarchies do |t|
      t.integer :parentId
      t.integer :childId
      t.string :type
      t.timestamps
    end
  end
end

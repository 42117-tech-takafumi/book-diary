class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.string :publisher_name, null: false
      t.string :isbn
      t.string :books_genre_id
      t.string :genre_id1
      t.string :genre_id2
      t.integer :rating, null: false
      t.text :item_caption
      t.text :comment, null: false
      #t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end

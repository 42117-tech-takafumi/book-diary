class Review < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  #belongs_to :tag
  belongs_to_active_hash :tag1, class_name: 'Tag', foreign_key: 'tag_id1'
  belongs_to_active_hash :tag2, class_name: 'Tag', foreign_key: 'tag_id2'

  #アソシエーション
  belongs_to :user

  #ヴァリデーション
  validates :title, :author, :publisher_name, :comment, presence: true
  validates :isbn, uniqueness: { scope: :user_id, message: "が重複しています。あなたは既にこのISBNの書籍の感想を投稿しています。" }

  validates :tag_id1,numericality: { other_than: 1, message: "は必ず選んで下さい"}

end

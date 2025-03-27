class Review < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  #belongs_to :tag
  belongs_to_active_hash :tag1, class_name: 'Tag', foreign_key: 'tag_id1'
  belongs_to_active_hash :tag2, class_name: 'Tag', foreign_key: 'tag_id2'

  #アソシエーション
  belongs_to :user

  #ヴァリデーション
  validates :title, :author, :publisher_name, :comment, presence: true
  validates :isbn, uniqueness: { scope: :user_id, message: "is duplicated. You have already written the review for this book." }

  validates :tag_id1,numericality: { other_than: 1, message: "can't be blank"}

end

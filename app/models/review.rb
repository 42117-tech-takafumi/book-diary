class Review < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to :tag

  #アソシエーション
  belongs_to :user

  #ヴァリデーション
  validates :title, :author, :publisher_name, :comment, presence: true
  validates :isbn, uniqueness: { scope: :user_id, message: "is duplicated. You have already written the review for this book." }

end

class Review < ApplicationRecord

  #アソシエーション
  belongs_to :user

  #ヴァリデーション
  validates :title, :author, :publisher_name, :comment, presence: true

  #ratingは別でバリデーション書く（1~3のいずれかを選ぶ仕様にする予定）
  #validates :rating,  numericality: { other_than: 1, message: "can't be blank"} 

end

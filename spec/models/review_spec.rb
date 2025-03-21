require 'rails_helper'
RSpec.describe Review, type: :model do
  before do
    user = FactoryBot.create(:user)
    @review = FactoryBot.build(:review, user_id: user.id)
    @review2 = FactoryBot.create(:review, user_id: user.id , isbn:"9876543210")
  end

  describe '本の感想の新規投稿' do
    context '新規投稿できるとき' do
      it 'title、author、publisher_name、comment、user_idが存在すれば投稿できる' do
        expect(@review).to be_valid
      end
      it '上記のカラムが存在すればimage_url、isbn、books_genre_id、books_genre_name、tag_id1、tag_id2、item_captionが空でも投稿できる' do
        @review.image_url=""
        @review.isbn=""
        @review.books_genre_id=""
        @review.books_genre_name=""
        @review.tag_id1=""
        @review.tag_id2=""
        @review.item_caption=""
        expect(@review).to be_valid
      end
    end

    context '新規投稿できないとき' do
      it 'titleが空では投稿できない' do
        @review.title=""
        @review.valid?
        expect(@review.errors.full_messages).to include("Title can't be blank")
      end
      it 'authorが空では投稿できない' do
        @review.author=""
        @review.valid?
        expect(@review.errors.full_messages).to include("Author can't be blank")
      end
      it 'publisher_nameが空では投稿できない' do
        @review.publisher_name=""
        @review.valid?
        expect(@review.errors.full_messages).to include("Publisher name can't be blank")
      end
      it 'commentが空では投稿できない' do
        @review.comment=""
        @review.valid?
        expect(@review.errors.full_messages).to include("Comment can't be blank")
      end
      it 'ユーザーが紐付いていなければ投稿できない' do
        @review.user = nil
        @review.valid?
        expect(@review.errors.full_messages).to include('User must exist')
      end
      it 'user_idとisbnが同じデータが既にある場合は投稿できない' do
        @review.isbn="9876543210"
        @review.valid?
        expect(@review.errors.full_messages).to include('Isbn is duplicated. You have already written the review for this book.')
      end
    end
  end
end

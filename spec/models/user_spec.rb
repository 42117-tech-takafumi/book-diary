require 'rails_helper'
RSpec.describe User, type: :model do
  before do
    @user = FactoryBot.build(:user)
  end

  describe 'ユーザー新規登録' do
    context '新規登録できる時' do
      it 'nicknameとemail、passwordとpassword_confirmationが存在すれば登録できる' do
        expect(@user).to be_valid
      end
    end

    context '新規登録できない時' do
      it 'nicknameが空では登録できない' do
        @user.nickname=""
        @user.valid?
        expect(@user.errors.full_messages).to include("ニックネームを入力してください")
      end
      it 'emailが空では登録できない' do
        @user.email=""
        @user.valid?
        expect(@user.errors.full_messages).to include("Eメールを入力してください")
      end
      it 'passwordが空では登録できない' do
        @user.password=""
        @user.valid?
        expect(@user.errors.full_messages).to include("パスワードを入力してください")
      end
      it 'passwordとpassword_confirmationが不一致では登録できない' do
        @user.password="123456"
        @user.password_confirmation="654321"
        @user.valid?
        expect(@user.errors.full_messages).to include("パスワード（確認用）とパスワードの入力が一致しません")
      end
      it '重複したemailが存在する場合は登録できない' do
        @user.save
        another_user = FactoryBot.build(:user)
        another_user.email = @user.email
        another_user.valid?
        expect(another_user.errors.full_messages).to include('Eメールはすでに存在します')
      end
      it 'emailは@を含まないと登録できない' do
        @user.email="testmail"
        @user.valid?
        expect(@user.errors.full_messages).to include("Eメールは不正な値です")
      end
      it 'passwordが5文字以下では登録できない' do
        @user.password="12345"
        @user.password_confirmation="12345"
        @user.valid?
        expect(@user.errors.full_messages).to include("パスワードは6文字以上で入力してください")
      end
      it 'passwordが129文字以上では登録できない' do
        @user.password = Faker::Internet.password(min_length: 129, max_length: 150)
        @user.password_confirmation = @user.password
        @user.valid?
        expect(@user.errors.full_messages).to include("パスワードは128文字以内で入力してください")
      end
      it 'passwordが半角数字のみの場合は登録できない' do
        @user.password="1234567"
        @user.password_confirmation="1234567"
        @user.valid?
        expect(@user.errors.full_messages).to include("パスワードには英字と数字の両方を含めてください")
      end
      it 'passwordが半角英字のみの場合は登録できない' do
        @user.password="abcdefg"
        @user.password_confirmation="abcdefg"
        @user.valid?
        expect(@user.errors.full_messages).to include("パスワードには英字と数字の両方を含めてください")
      end
      it 'passwordが全角の場合は登録できない' do
        @user.password="ＡＢＣＤＥＦＧ１２"
        @user.password_confirmation="ＡＢＣＤＥＦＧ１２"
        @user.valid?
        expect(@user.errors.full_messages).to include("パスワードには英字と数字の両方を含めてください")
      end
    end
  end

end

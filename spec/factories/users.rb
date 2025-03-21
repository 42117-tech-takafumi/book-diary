FactoryBot.define do
  factory :user do
    nickname              {'test'}
    email                 {Faker::Internet.email}
    password              {'testpassword12'}
    password_confirmation {password}
  end
end
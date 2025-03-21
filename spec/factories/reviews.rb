FactoryBot.define do
  factory :review do
    title                 {'test_title'}
    image_url             {Faker::Lorem.sentence}
    author                {Faker::Lorem.sentence}
    publisher_name        {Faker::Lorem.sentence}
    isbn                  {"0123456789"}
    books_genre_id        {"001001"}
    books_genre_name      {"test_genre"}
    tag_id1               {2}
    tag_id2               {3}
    item_caption          {Faker::Lorem.sentence}
    comment               {Faker::Lorem.sentence}

    association :user
  end
end

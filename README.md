# テーブル設計

## users テーブル

| Column             | Type   | Options     |
| ------------------ | ------ | ----------- |
| email              | string | null: false, unique: true |
| encrypted_password | string | null: false |
| nickname           | string | null: false |

### Association

- has_many :reviews

## reviews テーブル

| Column                 | Type       | Options     |
| ---------------------- | ---------- | ----------- |
| title                  | string     | null: false |
| image_url              | string     |             |
| author                 | string     | null: false |
| publisher_name         | string     | null: false |
| isbn                   | string     |             |
| books_genre_id         | string     |             |
| books_genre_name       | string     |             |
| tag_id1                | integer    |             |
| tag_id2                | integer    |             |
| item_caption           | text       |             |
| comment                | text       | null: false |
| user                   | references | null: false, foreign_key: true |

### Association

- belongs_to :user
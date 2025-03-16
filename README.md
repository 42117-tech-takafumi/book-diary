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
| author                 | string     | null: false |
| publisher_name         | string     | null: false |
| isbn                   | string     |             |
| books_genre_id         | string     |             |
| genre_id1              | string     |             |
| genre_id2              | string     |             |
| rating                 | integer    | null: false |
| item_caption           | text       |             |
| comment                | text       | null: false |
| user                   | references | null: false, foreign_key: true |

### Association

- belongs_to :user
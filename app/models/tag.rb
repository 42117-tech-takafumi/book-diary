class Tag < ActiveHash::Base
  self.data = [
    { id: 1, name: '---' },
    { id: 2, name: 'ミステリー・サスペンス' },
    { id: 3, name: 'SF' },
    { id: 4, name: 'ホラー' },
    { id: 5, name: 'エッセイ' },
    { id: 6, name: '外国の小説' },
    { id: 7, name: 'ロマンス' },
    { id: 8, name: 'ファンタジー' }
  ]

  include ActiveHash::Associations
  has_many :reviews

 end
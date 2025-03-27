class Tag < ActiveHash::Base
  self.data = [
    { id: 1, name: '---' },
    { id: 2, name: 'ミステリー・サスペンス' },
    { id: 3, name: 'SF' },
    { id: 4, name: 'ホラー' },
    { id: 5, name: 'エッセイ' },
    { id: 6, name: 'ロマンス' },
    { id: 7, name: 'ファンタジー' },
    { id: 8, name: 'ノンフィクション' }
  ]

  include ActiveHash::Associations
  has_many :reviews

 end
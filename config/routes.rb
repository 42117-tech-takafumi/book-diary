Rails.application.routes.draw do
  root to: "reviews#index"
  
  resources :reviews do
    collection do
      get :search #APIから本を検索するためのアクション
    end
  end
  
end

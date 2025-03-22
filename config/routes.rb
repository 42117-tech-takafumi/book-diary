Rails.application.routes.draw do
  devise_for :users
  root to: "reviews#index"
  
  resources :reviews do
    collection do
      get :search #APIから本を検索するためのアクション
    end
  end

  resources :users, only: :show
  
end

Rails.application.routes.draw do
  devise_for :users
  root to: "reviews#index"
  
  resources :reviews do
    collection do
      #APIから本を検索するためのアクションとお薦めの本を探すためのアクション
      get :search, :recommend
    end
  end

  resources :users, only: :show
  
end

Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # -------Content info----------
  resources :books, only: %i[index show]
  resources :movies, only: %i[index show]
  resources :musics, only: %i[index show]
  resources :summaries, only: %i[index]


  # -------Creator info----------
  get '/my_creators', to: 'creators#my_creators', as: :my_creators
  get '/my_creators/new', to: 'creators#new'
  post '/my_creators', to: 'creators#create', as: :create_creator
  delete '/my_creators/:id', to: 'creators#destroy', as: :delete_creator

  get '/auth/spotify/callback', to: 'users#spotify'
  # ^Going to get it through current_user and get creators using through user_creators- current_user.creators

  # -------Favorite Content -----

  get '/favorite_movies/:id', to: 'movies#favorite_movie', as: :favorite_movie
  get '/music', to: 'albums#favorite_album', as: :favorite_album
  get '/music', to: 'concerts#favorite_concert', as: :favorite_concert
  get '/books', to: 'books#favorite_book', as: :favorite_book
  get '/my_favorites', to: 'users#my_favorites', as: :user_favorites
end

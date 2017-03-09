Rails.application.routes.draw do

  resources :public_view, only: [:show]

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  Hydra::BatchEdit.add_routes(self)
  mount Qa::Engine => '/authorities'

  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_scope :user do
    get "/users/sign_up", to: redirect('/404')
    post "/users", to: redirect('/404')

    get "/login" => "users/sessions#new"

    # used only to prevent errors in development.
    # netbadge will catch this path in prod
    get "/logout", to: "users/sessions#new"
  end

  devise_for :users, controllers: { sessions: 'users/sessions' }


  mount CurationConcerns::Engine, at: '/'
  resources :welcome, only: 'index'
  root 'dashboard#index'
  curation_concerns_collections
  curation_concerns_basic_routes
  curation_concerns_embargo_management
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  mount Sufia::Engine, at: '/'


end

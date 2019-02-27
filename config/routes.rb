Rails.application.routes.draw do

  # libra-oc specific endpoints
  get '/audits' => 'audits#index'
  get '/exports' => 'exports#index'
  get '/exports/get' => 'exports#export'
  get '/computing_id' => 'ajax#computing_id'
  get '/test_email' => 'test_email#test_email'

  get 'help' => redirect('https://www.library.virginia.edu/askalibrarian/')
  get 'oc_checklist' => redirect('https://www.library.virginia.edu/libra/open/oc-checklist/')

  resources :public_view, only: [:show]

  concern :exportable, Blacklight::Routes::Exportable.new

  # health check and version endpoints
  resources :healthcheck, only: [ :index ]
  resources :version, only: [ :index ]

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  get '/uva-public-license' => redirect('https://www.library.virginia.edu/libra/open/libra-public-deposit-license/')
  get '/uva-only-license' => redirect('https://www.library.virginia.edu/libra/open/libra-uva-only-deposit-license/')
  get '/agreement' => redirect('https://www.library.virginia.edu/libra/open/libra-deposit-license/')

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

  namespace 'orcid' do
    get :landing
    delete :destroy
  end

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

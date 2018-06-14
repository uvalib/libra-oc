Rails.application.routes.draw do

  # libra-oc specific endpoints
  get '/audits' => 'audits#index'
  get '/exports' => 'exports#index'
  get '/exports/get' => 'exports#export'
  get '/computing_id' => 'ajax#computing_id'
  get '/test_email' => 'test_email#test_email'

  get 'help' => redirect('http://www.library.virginia.edu/askalibrarian/')

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

  get '/uva-public-license' => redirect('http://www.library.virginia.edu/libra/open-access/libra-public-deposit-license/')
  get '/uva-only-license' => redirect('http://www.library.virginia.edu/libra/open-access/libra-uva-only-deposit-license/')
  get '/agreement' => redirect('http://www.library.virginia.edu/libra/open-access/libra-deposit-license/')

  root 'hyrax/dashboard#index'
  mount Hyrax::Engine, at: '/'
  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'
  mount Qa::Engine => '/authorities'

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

  resources :welcome, only: 'index'
  concern :exportable, Blacklight::Routes::Exportable.new

  curation_concerns_basic_routes
  curation_concerns_embargo_management

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



end

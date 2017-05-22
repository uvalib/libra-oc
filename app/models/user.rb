class User < ApplicationRecord
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Curation Concerns behaviors.
  include CurationConcerns::User
  # Connects this user object to Sufia behaviors.
  include Sufia::User
  include Sufia::UserUsageStats

  # helpers, etc for libraoc users
  include Libraoc::UserAttributes

  # support to persist the ORCID on an external service
  include Libraoc::OrcidBehavior

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :rememberable, :trackable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def computing_id
    email[/^.*@/].chop
  end

  #
  # use the existing sufia role mapper to determine who is an admin
  #
  def admin?
    groups.include?( 'admin' )
  end

  #
  # history of audits for this user
  #
  def audit_history
    return [] if computing_id.blank?
    return Audit.where( user_id: computing_id ).order( created_at: :desc )
  end

end

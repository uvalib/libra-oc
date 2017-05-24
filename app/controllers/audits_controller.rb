class AuditsController < ApplicationController

  before_action :enforce_user_is_admin

  # # GET /audits
  def index
    @audits = Audit.all.order( created_at: :desc )
  end

end

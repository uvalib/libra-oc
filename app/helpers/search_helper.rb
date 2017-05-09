module SearchHelper

  def search_scope
    if current_user && current_user.admin?
      main_app.search_catalog_path
    else
      sufia.dashboard_works_path
    end
  end
end

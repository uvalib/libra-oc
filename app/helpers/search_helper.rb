module SearchHelper

  def search_scope
    if current_user && current_user.admin?
      main_app.search_catalog_path
    else
      hyrax.dashboard_works_path
    end
  end

  def search_scope_placeholder_text
    if current_user && current_user.admin?
      return t("hyrax.search.form.q.placeholder_all_scope")
    else
      return t("hyrax.search.form.q.placeholder_my_scope")
    end
  end
end

module SufiaWorksOverrides
  protected
  def after_create_response
    respond_to do |wants|
      wants.html do
        if params.fetch(:uploaded_files, []).any?
          flash[:notice] = t('sufia.works.create.after_create_html', application_name: view_context.application_name)
        end
        redirect_to [main_app, curation_concern]
      end
      wants.json { render :show, status: :created, location: polymorphic_path([main_app, curation_concern]) }
    end
  end


end

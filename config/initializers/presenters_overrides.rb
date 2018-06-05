Hyrax::PermissionBadge.class_eval do

  private

    def dom_label_class
      if open_access_with_embargo?
        'label-warning'
      elsif open_access?
        'label-success'
      elsif registered?
        'label-warning'
      else
        'label-danger'
      end
    end

    def link_title
      if open_access_with_embargo?
        'Open Access with Embargo'
      elsif open_access?
        'Visible Worldwide'
      elsif registered?
        'Restricted to UVa Only'
      else
        'Private'
      end
    end

end


CurationConcerns::PermissionBadge.class_eval do

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

end


class LibraWorkPresenter < Sufia::WorkShowPresenter

  # add our custom fields to the presenter
  delegate :authors,
           :contributors,
           :notes,
           :admin_notes,
           :published_date,
           :sponsoring_agency,
           :license,
           :doi,
           :libra_id,
           :work_source,
           :abstract,
           :keywords,


     to: :solr_document


end

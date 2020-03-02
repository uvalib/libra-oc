class LibraOcIndexer < CurationConcerns::WorkIndexer

  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('authors')] = object.authors
      solr_doc[Solrizer.solr_name('authors_display', :facetable)] = object.authors.map &:to_display
      solr_doc[Solrizer.solr_name('contributors')] = object.contributors
      solr_doc[Solrizer.solr_name('contributors_display', :facetable)] = object.contributors.map &:to_display
      solr_doc[Solrizer.solr_name('notes', :searchable)] = object.notes
      solr_doc[Solrizer.solr_name('thumbnail_url_display', :displayable)] = object.thumbnail_url
      solr_doc[Solrizer.solr_name('rights_display', :displayable)] = rights_labels(object)
      solr_doc[Solrizer.solr_name('rights_url', :displayable)] = rights_urls(object)
      solr_doc[Solrizer.solr_name('orcid_status', :searchable)] = object.orcid_status
      solr_doc[Solrizer.solr_name('orcid_put_code', :searchable)] = object.orcid_put_code
      solr_doc[Solrizer.solr_name('author_orcid_url', :searchable)] = object.author_orcid_url

    end
  end

  private
  def rights_labels doc
    doc.rights.map do |r|
      CurationConcerns.config.license_service_class.new.label(r)
    end if doc.rights.present?
  end
  def rights_urls doc
    doc.rights.map do |r|
      CurationConcerns.config.license_service_class.new.url(r)
    end if doc.rights.present?
  end
end

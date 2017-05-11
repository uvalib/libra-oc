class LibraOcIndexer < CurationConcerns::WorkIndexer

  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('authors')] = object.authors
      solr_doc[Solrizer.solr_name('authors_display', :facetable)] = object.authors.map &:to_display
      solr_doc[Solrizer.solr_name('contributors')] = object.contributors
      solr_doc[Solrizer.solr_name('contributors_display', :facetable)] = object.contributors.map &:to_display
      solr_doc[Solrizer.solr_name('notes', :searchable)] = object.notes
      solr_doc[Solrizer.solr_name('thumbnail_url_display', :displayable)] = object.thumbnail_url
    end
  end
end

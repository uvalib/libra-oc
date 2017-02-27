class LibraOcIndexer < CurationConcerns::WorkIndexer

  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('authors')] = object.authors
      solr_doc[Solrizer.solr_name('contributors')] = object.contributors

    end
  end
end

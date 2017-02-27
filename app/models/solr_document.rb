# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  # Adds CurationConcerns behaviors to the SolrDocument.
  include CurationConcerns::SolrDocumentBehavior
  # Adds Sufia behaviors to the SolrDocument.
  include Sufia::SolrDocumentBehavior



  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # Do content negotiation for AF models. 

  use_extension( Hydra::ContentNegotiation )

  #
  # Libra OC related below
  #

  # doesnt work
  def authors
    self[Solrizer.solr_name('authors')]
  end

  def contributors
    self[Solrizer.solr_name('contributors')]
  end

  def sponsoring_agency
    self[Solrizer.solr_name('sponsoring_agency')]
  end

  def sponsoring_agency
    self[Solrizer.solr_name('sponsoring_agency')]
  end


  def notes
    self[Solrizer.solr_name('notes')]
  end

  def admin_notes
    self[Solrizer.solr_name('admin_notes')]
  end

  def license
    self[Solrizer.solr_name('license')]
  end

  def doi
    self[Solrizer.solr_name('doi')]
  end

  def libra_id
    self[Solrizer.solr_name('libra_id')]
  end

  def work_source
    self[Solrizer.solr_name('work_source')]
  end

  def published_date
    self[Solrizer.solr_name('published_date')]
  end

  def abstract
    self[Solrizer.solr_name('abstract')]
  end





end

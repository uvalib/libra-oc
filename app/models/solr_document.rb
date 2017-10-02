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

  def authors
    # TODO: for some reason, SOLR will sometimes receive duplicate values so de-duplicate here
    values = self[Solrizer.solr_name('authors')]
    values = values.uniq if values
    return values
  end

  def contributors
    # TODO: for some reason, SOLR will sometimes receive duplicate values so de-duplicate here
    values = self[Solrizer.solr_name('contributors')]
    values = values.uniq if values
    return values
  end

  #
  # TODO: this does not really belong here...
  #
  def audit_history
    return Audit.where( work_id: id ).order( created_at: :desc )
  end

  def authors_display
    person_display 'authors'
  end

  def contributors_display
    person_display 'contributors'
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

  def source_citation
    self[Solrizer.solr_name('source_citation')]
  end

  def published_date
    self[Solrizer.solr_name('published_date')]
  end

  def date_created
    self[Solrizer.solr_name('date_created')]
  end

  def date_modified
    self['date_modified_dtsi']
  end

  def abstract
    self[Solrizer.solr_name('abstract')]
  end

  def email_status
    self[Solrizer.solr_name('email_status')]
  end

  def rights_display
    self['rights_display_ssm']
  end

  def file_set_ids
    self['member_ids_ssim']
  end

  def orcid_status
    orcid_status = self[Solrizer.solr_name('orcid_status')]
    LibraWork::ORCID_STATUSES[ orcid_status.first.to_sym ] if orcid_status
  end

  #
  # is this work publicly visible?
  #
  def is_publicly_visible?
    return false if visibility.nil?
    return( visibility == 'open' )
  end

  #
  # is this work visible within the institution?
  #
  def is_institution_visible?
    return false if visibility.nil?
    return( visibility == 'authenticated' )
  end

  #
  # is this work private to the depositor?
  #
  def is_private?
    return true if visibility.nil?
    return( self.visibility == 'restricted' )
  end

  private

  def person_display solr_name
    # TODO: for some reason, SOLR will sometimes receive duplicate values so de-duplicate here
    values = self[Solrizer.solr_name(solr_name)]
    return nil unless values.present?
    values = values.map {|v| JSON.parse(v) }
    values.uniq!
    results = values.sort!{|s1,s2| s1['index'] <=> s2['index']}.map do |a|
      begin
        #puts "==> person_display: #{a.inspect}"
        email = ''
        email = User.email_from_cid( a['computing_id'] ) if a['computing_id'].present?
        email = "(#{email})" if email.present?
        "#{a['first_name']} #{a['last_name']} #{email}"
      rescue JSON::ParserError => e
        author
      end
    end
    return results
  end
end

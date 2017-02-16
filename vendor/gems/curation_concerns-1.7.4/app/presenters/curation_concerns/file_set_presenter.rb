module CurationConcerns
  class FileSetPresenter
    include ModelProxy
    include PresentsAttributes
    include CurationConcerns::CharacterizationBehavior
    attr_accessor :solr_document, :current_ability, :request

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :image?, :video?,
             :audio?, :pdf?, :office_document?, :representative_id, :to_s, to: :solr_document

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, to: :solr_document

    # Metadata Methods
    delegate :title, :label, :description, :creator, :contributor, :subject,
             :publisher, :language, :date_uploaded, :rights,
             :embargo_release_date, :lease_expiration_date,
             :depositor, :keyword, :title_or_label, to: :solr_document

    def page_title
      label
    end

    def link_name
      current_ability.can?(:read, id) ? label : 'File'
    end

    def single_use_links
      @single_use_links ||= SingleUseLink.where(itemId: id).map { |link| link_presenter_class.new(link) }
    end

    private

      def link_presenter_class
        CurationConcerns::SingleUseLinkPresenter
      end
  end
end

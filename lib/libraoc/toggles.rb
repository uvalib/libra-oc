module Toggles

  def self.config( &block )
    @config ||= Toggles::Configuration.new
    yield @config if block
    @config
  end

  class Configuration

    attr_writer :expose_collections
    def expose_collections
      @expose_collections
    end

    attr_writer :expose_follows
    def expose_follows
      @expose_follows
    end

    attr_writer :expose_highlights
    def expose_highlights
      @expose_highlights
    end

    attr_writer :expose_ownership_transfer
    def expose_ownership_transfer
      @expose_ownership_transfer
    end

    attr_writer :expose_work_share
    def expose_work_share
      @expose_work_share
    end

    attr_writer :expose_search
    def expose_search
      @expose_search
    end

    def initialize
      @expose_collections = true
      @expose_follows = true
      @expose_highlights = true
      @expose_ownership_transfer = true
      @expose_work_share = true
      @expose_search = true
    end

  end

end

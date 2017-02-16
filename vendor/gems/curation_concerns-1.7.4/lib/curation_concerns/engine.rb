# Load blacklight which will give curation_concerns views a higher preference than those in blacklight
require 'blacklight'
require 'hydra-editor'
require 'jquery-ui-rails'
require 'qa'
require 'sprockets/es6'

module CurationConcerns
  # Ensures that routes to curation_concerns are prefixed with `curation_concerns_`
  # def self.use_relative_model_naming?
  #   false
  # end

  class Engine < ::Rails::Engine
    isolate_namespace CurationConcerns
    require 'awesome_nested_set'
    require 'breadcrumbs_on_rails'
    require 'rdf/vocab'
    require 'highcharts-rails'

    config.autoload_paths += %W(
      #{config.root}/app/actors/concerns
      #{config.root}/lib
    )

    initializer 'curation_concerns.initialize' do
      require 'curation_concerns/rails/routes'
    end

    initializer 'curation_concerns.assets.precompile' do |app|
      app.config.assets.paths << config.root.join('app', 'assets', 'images')

      app.config.assets.precompile += %w(*.png *.gif)
    end

    initializer 'requires' do
      require 'curation_concerns/noid'
      require 'curation_concerns/permissions'
      require 'curation_concerns/lockable'
      require 'power_converters'
      require 'dry/struct'
      require 'dry/equalizer'
      require 'dry/validation'
    end

    initializer 'configure' do
      CurationConcerns.config.tap do |c|
        Hydra::Derivatives.ffmpeg_path    = c.ffmpeg_path
        Hydra::Derivatives.temp_file_base = c.temp_file_base
        Hydra::Derivatives.fits_path      = c.fits_path
        Hydra::Derivatives.enable_ffmpeg  = c.enable_ffmpeg

        ActiveFedora::Base.translate_uri_to_id = c.translate_uri_to_id
        ActiveFedora::Base.translate_id_to_uri = c.translate_id_to_uri
        ActiveFedora::Noid.config.template = c.noid_template
        ActiveFedora::Noid.config.statefile = c.minter_statefile
      end
    end

    rake_tasks do
      load File.expand_path('../../../tasks/workflow.rake', __FILE__)
    end
  end
end

# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

require 'rack'
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

use Rack::Deflater, if: ->(_, _, _, body) { body.respond_to?( :map ) && body.map(&:bytesize).reduce(0, :+) > 512 }
use Prometheus::Middleware::Exporter
use Prometheus::Middleware::Collector,

# we customize these because we dont want to keep distinct metrics for every work or file view
counter_label_builder: ->(env, code) {
  # normalize path, replace work IDs to keep cardinality low.
  normalized_path = env['PATH_INFO'].to_s.
      gsub(/\/public_view\/.*$/, '/public_view/:id').
      gsub(/\/downloads\/.*$/, '/downloads/:id').
      gsub(/\/concern\/libra_works\/.*$/, '/concern/libra_works/:id').
      gsub(/\/concern\/file_sets\/.*$/, '/concern/file_sets/:id')

      {
      code:         code,
      method:       env['REQUEST_METHOD'].downcase,
      path:         normalized_path
  }
},
duration_label_builder: -> ( env, code ) {
  # normalize path, replace work IDs to keep cardinality low.
  normalized_path = env['PATH_INFO'].to_s.
      gsub(/\/public_view\/.*$/, '/public_view/:id').
      gsub(/\/downloads\/.*$/, '/downloads/:id').
      gsub(/\/concern\/libra_works\/.*$/, '/concern/libra_works/:id').
      gsub(/\/concern\/file_sets\/.*$/, '/concern/file_sets/:id')

  {
      method:       env['REQUEST_METHOD'].downcase,
      path:         normalized_path
  }
}

run Rails.application
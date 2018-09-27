require 'ruby-progressbar'

namespace :libraoc do

  namespace :index do

    desc "Reindex SOLR from a Fedora repo"
    task solr_reindex: :environment do
      ActiveFedora::Base.reindex_everything( progress_bar: true, final_commit: true )
      puts "done"
    end
  end
end

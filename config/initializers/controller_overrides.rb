#require_dependency 'libraoc/helpers/statistics_helper'

DownloadsController.class_eval do

  include StatisticsHelper

  #
  # override so we can generate a download event whenever a file is downloaded
  # standard sufia uses google analytics for this and this approach was easier
  # than integrating with piwik
  #
  def show

    #
    # assume we need a file download event unless the file is a string. This means that the
    # file is a thumbnail (special sufia magic) and we dont want a download event when downloading
    # thumbnails
    #
    if file.kind_of?( String ) == false
      # save file download statistics
      file_download_event( params['id'], current_user )
    end
    super
  end

  #
  # override so we can specify a different file set presenter and generate an audit record when
  # we destroy an existing fileset.
  #
  CurationConcerns::FileSetsController.class_eval do

    self.show_presenter = LibraFileSetPresenter

    def destroy
      create_audit( params[ 'id' ] )
      super
    end

    private

    def create_audit( id )
      begin
        fs = FileSet.find( id )
        work_id = fs.in_works.first.id
        FilesetRemovedAuditJob.perform_later( work_id, fs.label, current_user )
      rescue => ex
        # do nothing...
      end
    end
  end

end


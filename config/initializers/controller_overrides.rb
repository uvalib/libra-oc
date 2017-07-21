#
# override so we can generate a download event whenever a file is downloaded
# standard sufia uses google analytics for this and this approach was easier
# than integrating with piwik
#
DownloadsController.class_eval do

  include StatisticsHelper
  include VisibilityHelper

  def show

    #
    # assume we need a file download event unless the file is a string. This means that the
    # file is a thumbnail (special sufia magic) and we dont want a download event when downloading
    # thumbnails
    #
    if file.kind_of?( String ) == false
      # save file download statistics
      file_download_event( params['id'] )
    end
    super
  end

  #
  # we need to customize the determination on whether someone can download files associated with a work
  #
  def authorize_download!

    begin
      # attempt to get the asset to determine if it is downloadable
      if asset && asset.in_works.first
         can_download =  can_download_files?( asset.in_works.first )
         # if we can download, bail out here...
         return if can_download
      end
    rescue => ex
      # do nothing and let the sufia classes handle this
    end

    super
  end

  protected

  def file_name
    params[:filename] || title_name ||
      file.original_name || (asset.respond_to?(:label) && asset.label) || file.id
  end

  #
  # Use custom title and include missing extension
  #
  def title_name
    if asset.respond_to?(:title)
      title = asset.title.first
      extension = File.extname(file.file_name.first)
      if title.ends_with? extension
        title
      else
        title + extension
      end
    end
  end

end

#
# override so we can specify a different file set presenter and generate an audit record when
# we destroy an existing fileset.
#
CurationConcerns::FileSetsController.class_eval do

  self.show_presenter = LibraFileSetPresenter

  def update
    create_update_audit( params[ 'id' ], params['file_set'][ 'title' ][ 0 ] )
    super
  end

  def destroy
    create_destroy_audit( params[ 'id' ] )
    super
  end

  private

  def create_update_audit( id, new_name )
    begin
      fs = FileSet.find( id )
      FilesetRenamedAuditJob.perform_later( fs, new_name, current_user )
    rescue => ex
      # do nothing...
    end
  end

  def create_destroy_audit( id )
    begin
      fs = FileSet.find( id )
      FilesetRemovedAuditJob.perform_later( fs, current_user )
    rescue => ex
      # do nothing...
    end
  end
end


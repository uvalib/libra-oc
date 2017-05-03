class ExportsController < ApplicationController

  before_action :enforce_user_is_admin

  # # GET /exports
  def index
  end

  #
  # export items to a csv
  #
  def export

    # basic validation
    the_type = validate_type( params[ :type ] )
    start_date = validate_date( params[ :start_date ] )
    end_date = validate_date( params[ :end_date ] )

    works = export_get( the_type, start_date, end_date )
    respond_to do |format|
      format.csv do
        render_csv_works_response( the_type, transform_to_libra_works( works ) )
      end
    end
  end

  private

  #
  # get records from SOLR based on the specified constraints
  #
  def export_get( the_type, start_date, end_date )

    # construct the query
    constraints = construct_query_constraints( the_type, start_date, end_date )

    puts "===> query: #{constraints}"
    res = []
    tstart = Time.now
    LibraWork.search_in_batches( constraints, {:rows => 999} ) do |group|
      elapsed = Time.now - tstart
      puts "===> extracted #{group.length} work(s) in #{elapsed}"
      res.push( *group )
      tstart = Time.now
    end
    puts "===> returning #{res.length} work(s)"
    return res
  end

  #
  # construct the SOLR query constraints
  #
  def construct_query_constraints( the_type, start_date, end_date )

    constraints = "has_model_ssim:LibraWork"
    constraints += " AND ( system_create_dtsi:#{make_solr_date_search( start_date, end_date )}"
    constraints += " OR system_modified_dtsi:#{make_solr_date_search( start_date, end_date )})"
    return( constraints ) if the_type == 'all'

    constraints += " AND read_access_group_ssim:public" if the_type == 'public'
    constraints += " AND read_access_group_ssim:registered" if the_type == 'uva'
    constraints += " AND -read_access_group_ssim:[* TO *]" if the_type == 'private'
    return( constraints )
  end

  #
  # build a SOLR date range search based on specified dates
  #
  def make_solr_date_search( start_date, end_date )
    date_start = '*'
    date_start = "#{start_date}T00:00:00Z" if convert_date( start_date ) != nil
    date_end = '*'
    date_end = "#{end_date}T23:59:59Z" if convert_date( end_date ) != nil
    return "[#{date_start} TO #{date_end}]"
  end

  #
  # convert a string date (YYYY-MM-DD) to a datetime object or return nil if it fails
  #
  def convert_date( date )
    begin
      return DateTime.strptime( date, '%Y-%m-%d' )
    rescue => e
      return nil
    end
  end

  #
  # render a csv response
  #
  def render_csv_works_response( the_type, works )
    @works = works
    filename = "works-#{the_type}.csv"
    headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    headers['Content-Type'] ||= 'text/csv'
    render 'csv/v1/works'
  end

  #
  # validate the supplied export type and default to public
  #
  def validate_type( the_type )

    return 'public' if the_type.nil?
    case the_type
      when 'all', 'public', 'uva', 'private'
        return( the_type )
      else
        return( 'public' )
    end

  end

  #
  # validate the supplied date (YYYY-MM-DD) and return today if invalid
  #
  def validate_date( date )
    return Time.now.strftime( '%Y-%m-%d' ) if date.nil?
    dt = convert_date( date )
    return Time.now.strftime( '%Y-%m-%d' ) if dt.nil?
    return dt.strftime( '%Y-%m-%d' )
  end

  #
  # transform an array of SOLR works to an array of LibraWorks
  #
  def transform_to_libra_works( works )
    res = []
    works.each do |w|
      begin
        res << LibraWork.find( w['id'] )
      rescue => e
        # ignore errors
      end
    end
    return res
  end
end

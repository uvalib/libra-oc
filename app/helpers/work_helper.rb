module WorkHelper

  #
  # get a work and handle the reasonable failure cases by returning nil, pass up the exception otherwise
  #
  def get_work_item( id )

    begin
       work = LibraWork.find( id )
       return work
    rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone, Ldp::HttpError, URI::InvalidURIError => ex
       puts "==> get_work_item exception: #{ex}"
       return nil
    end

  end

end

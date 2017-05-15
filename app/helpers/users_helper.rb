module UsersHelper

  def orcid_details profile

    output = ''
    removed = %w(relevancy uri)
    profile.except(*removed).each do |k, v|
      output += content_tag :p do
        content_tag( :b, k.titleize + ': ') + content_tag( :span, v.respond_to?(:join) ? v.join(', ') : v )
      end
    end
    output.html_safe
  end
end

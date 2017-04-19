class Author < ActiveFedora::Base
  include Libraoc::PersonMetadata

  has_many :libra_works, inverse_of: :authors, class_name: 'LibraWork'

end

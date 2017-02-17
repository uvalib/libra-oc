class Contributor < ActiveFedora::Base
  include Libraoc::PersonMetadata

  has_many :libra_works, inverse_of: :contributors, class_name: 'LibraWork'

end

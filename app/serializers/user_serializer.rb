class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :full_name, :accepted_terms_version
end

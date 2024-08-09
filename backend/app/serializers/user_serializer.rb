class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :uuid, :avatar_url
end
# frozen_string_literal: true

if user.persisted?
  json.user do
    json.partial! @user
  end
else
  json.errors user.errors.full_messages
end

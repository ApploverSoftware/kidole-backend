json.auth_token do
  json.token @auth_token[:token]
  json.device @auth_token[:device]
end
json.user do
  json.username @user.username
  json.phone_number @user.phone_number
  json.first_name @user.first_name
  json.last_name @user.last_name
  json.balances do
    ChainAsset.where('quorum IS NULL').each do |chain_asset|
      json.set!chain_asset.alias, @stats[chain_asset.alias] ? true : false
    end
    json.approval @stats["approval"] ? @stats["approval"] : 0
    json.disapproval @stats["disapproval"] ? @stats["disapproval"] : 0
  end
end
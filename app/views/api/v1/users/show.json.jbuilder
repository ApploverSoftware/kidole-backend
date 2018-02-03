# frozen_string_literal: true
json.user do
  json.partial! user
  json.balances do
    binding.pry
    ChainAsset.where('quorum IS NULL').each do |chain_asset|
      binding.pry
      json.set!chain_asset.alias, @stats[chain_asset.alias] ? true : false
    end
    json.approval @stats["approval"] ? @stats["approval"] : 0
    json.disapproval @stats["disapproval"] ? @stats["disapproval"] : 0
  end
end

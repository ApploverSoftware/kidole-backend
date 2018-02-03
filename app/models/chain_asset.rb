# frozen_string_literal: true

class ChainAsset < ApplicationRecord
  after_create :create_chain_asset
  validates :alias, uniqueness: true, presence: true
  serialize :definition, Hash
  serialize :keys, Array

  private

  def create_chain_asset
    chain = Chain::Client.new(access_token: Rails.application.secrets.chain_token,
                              url: Rails.application.secrets.chain_route)
    chain.assets.create(
      alias: self.alias,
      root_xpubs: keys,
      quorum: quorum,
      definition: {}
    )
  end
end

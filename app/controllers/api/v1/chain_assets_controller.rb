# frozen_string_literal: true

class Api::V1::ChainAssetsController < ApplicationController
  def create
    chain = Chain::Client.new(access_token: Rails.application.secrets.chain_token,
                              url: Rails.application.secrets.chain_route)
    signer = Chain::HSMSigner.new

    asset_key = chain.mock_hsm.keys.create
    asset_alias = asset_params[:alias] + current_user.username

    chain.assets.create(
        alias: asset_params[:alias] + current_user.username,
        root_xpubs: [asset_key.xpub],
        quorum: 1,
        definition: Hash[asset_params[:name], asset_params[:value]]
    )

    signer.add_key(asset_key, chain.mock_hsm.signer_conn)
    tx = chain.transactions.build do |b|
      b.issue asset_alias: asset_alias, amount: 1
      b.control_with_account account_alias: user.username, asset_alias: asset_alias, amount: 1
    end
    signed_tx = signer.sign(tx)
    chain.transactions.submit(signed_tx)
  end

  private

  def asset_params
    params.permit(:name, :alias, :value)
  end
end

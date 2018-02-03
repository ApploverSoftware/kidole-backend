# frozen_string_literal: true

class Api::V1::ChainAssetsController < Api::V1::ApiController
  def create
    return not_unique unless check_uniqueness(params[:name], params[:value])
    chain = Chain::Client.new(access_token: Rails.application.secrets.chain_token,
                              url: Rails.application.secrets.chain_route)
    signer = Chain::HSMSigner.new

    asset_key = chain.mock_hsm.keys.create
    asset_alias = "#{asset_params[:alias]}_#{current_user.username}"

    chain.assets.create(
        alias: asset_alias,
        root_xpubs: [asset_key.xpub],
        quorum: 1,
        definition: Hash[asset_params[:name], asset_params[:value]]
    )

    signer.add_key(asset_key, chain.mock_hsm.signer_conn)
    tx = chain.transactions.build do |b|
      b.issue asset_alias: asset_alias, amount: 1
      b.control_with_account account_alias: current_user.username, asset_alias: asset_alias, amount: 1
    end
    signed_tx = signer.sign(tx)
    chain.transactions.submit(signed_tx)
    head :created
  end

  def issue
    chain_asset = ChainAsset.find_by(alias: params[:alias])
    signer = Chain::HSMSigner.new
    user = User.find_by(username: params[:username])
    return duplicate_approval unless validate_single_approval(user, current_user)
    chain = Chain::Client.new(access_token: Rails.application.secrets.chain_token,
                              url: Rails.application.secrets.chain_route)
    signer.add_key(chain_asset.keys[0], chain.mock_hsm.signer_conn)
    signer.add_key(chain_asset.keys[1], chain.mock_hsm.signer_conn)
    tx = chain.transactions.build do |b|
      b.issue asset_alias: params[:alias], amount: 1
      b.control_with_account account_alias: current_user.username, asset_alias: params[:alias], amount: 1
    end

    signed_tx = signer.sign(tx)
    chain.transactions.submit(signed_tx)

    signer = Chain::HSMSigner.new
    signer.add_key(chain_asset.keys[0], chain.mock_hsm.signer_conn)
    signer.add_key(chain_asset.keys[1], chain.mock_hsm.signer_conn)
    signer.add_key(user.chain_key, chain.mock_hsm.signer_conn)
    signer.add_key(current_user.chain_key, chain.mock_hsm.signer_conn)
    payment = chain.transactions.build do |b|
      b.spend_from_account account_alias: current_user.username, asset_alias: params[:alias], amount: 1
      b.control_with_account account_alias: user.username, asset_alias: params[:alias], amount: 1
    end

    signed_payment = signer.sign(payment)

    chain.transactions.submit(signed_payment)
    head :created
  end

  private

  def asset_params
    params.permit(:name, :alias, :value)
  end

  def check_uniqueness(name, value)
    vals = []
    chain = Chain::Client.new(access_token: Rails.application.secrets.chain_token,
                              url: Rails.application.secrets.chain_route)
    balances = chain.balances.query(filter: "asset_definition.#{name}=$1",
                                    filter_params: [value])
    balances.each { |b|
      b.sum_by['asset_alias']
      vals << b.amount
    }
    return true if vals.empty?
  end

  def validate_single_approval(user, current_user)
    vals = []
    chain = Chain::Client.new(access_token: Rails.application.secrets.chain_token,
                              url: Rails.application.secrets.chain_route)
    chain.transactions.query(
        filter: 'inputs(account_alias=$1) OR outputs(account_alias=$2)',
        filter_params: [current_user.username, user.username],
    ).each do |tx|
      vals << tx.id
    end
    return true if vals.empty?
  end

  def not_unique
    render json: { errors: ["#{params[:name]} is already taken"] }, status: :unprocessable_entity
  end

  def duplicate_approval
    render json: { errors: ["Approval between those users already occured"] }, status: :unprocessable_entity
  end
end

# frozen_string_literal: true

class User < ApplicationRecord
  after_create :create_chain_account
  after_create :validate_phone_number

  has_many :auth_tokens, dependent: :destroy

  validates :phone_number, uniqueness: true, presence: true
  validates :username, uniqueness: true, presence: true
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :facebook_id, uniqueness: true, allow_nil: true
  validate  :matching_passwords, on: :create

  attr_accessor :password_confirmation

  has_secure_password

  def create_chain_account
    chain = Chain::Client.new(access_token: Rails.application.secrets.chain_token,
                              url: Rails.application.secrets.chain_route)
    key = chain.mock_hsm.keys.create
    signer = Chain::HSMSigner.new
    signer.add_key(key, chain.mock_hsm.signer_conn)

    chain.accounts.create(
      alias: username,
      root_xpubs: [key.xpub],
      quorum: 1
    )
    update(chain_key: key.xpub)
  end

  def validate_phone_number
    chain = Chain::Client.new(access_token: Rails.application.secrets.chain_token,
                              url: Rails.application.secrets.chain_route)
    signer = Chain::HSMSigner.new

    asset_key = chain.mock_hsm.keys.create
    asset_alias = "phone_number_#{username}"

    chain.assets.create(
      alias: asset_alias,
      root_xpubs: [asset_key.xpub],
      quorum: 1,
      definition: Hash['phone_number', phone_number]
    )

    signer.add_key(asset_key, chain.mock_hsm.signer_conn)
    tx = chain.transactions.build do |b|
      b.issue asset_alias: asset_alias, amount: 1
      b.control_with_account account_alias: username, asset_alias: asset_alias, amount: 1
    end
    signed_tx = signer.sign(tx)
    chain.transactions.submit(signed_tx)
  end

  def generate_auth_token
    token = SecureRandom.hex
    device = SecureRandom.hex
    AuthToken.create(user_id: id, token: User.digest(token), device: device)
    { token: token, device: device }
  end

  def self.digest(string)
    cost = if ActiveModel::SecurePassword.min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create(string, cost: cost)
  end

  def self.authenticated(remember_token, username, device)
    if (token = AuthToken.find_by(device: device)) && token.user.username == username
      BCrypt::Password.new(token.token).is_password?(remember_token)
      return token
    end
    nil
  end

  def invalidate_auth_token(token, login, device)
    User.authenticated(token, login, device).destroy
  end

  def get_balances
    chain = Chain::Client.new(access_token: Rails.application.secrets.chain_token,
                              url: Rails.application.secrets.chain_route)
    balances = {}
    chain.balances.query(
      filter: 'account_alias=$1',
      filter_params: [username]
    ).each do |b|
      name = b.sum_by['asset_alias'].rpartition('_')[0]
      name = name.blank? ? b.sum_by['asset_alias'] : name
      balances[name] = b.amount
    end
    balances
  end

  private

  def matching_passwords
    return true if password = password_confirmation
    else errors.add(:password_confirmation, "doesn't match password.")
  end
end

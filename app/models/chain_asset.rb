class ChainAsset < ApplicationRecord
  validates :alias, uniqueness: true, presence: true
  serialize :definition, Hash
end

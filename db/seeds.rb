# ChainAsset.create(alias: "authorized_email", definition: { email: "string" })
# ChainAsset.create(alias: "authorized_phone", definition: { phone_number: "string" })
# ChainAsset.create(alias: "authorized_instagram", definition: { instagram_id: "string" })
# ChainAsset.create(alias: "authorized_facebook", definition: { facebook_id: "string" })
chain = Chain::Client.new(access_token: Rails.application.secrets.chain_token,
                          url: Rails.application.secrets.chain_route)

asset_key = chain.mock_hsm.keys.create.xpub
asset_key2 = chain.mock_hsm.keys.create.xpub
ChainAsset.create(alias: "approval", quorum: 2, keys: [asset_key, asset_key2])

asset_key = chain.mock_hsm.keys.create.xpub
asset_key2 = chain.mock_hsm.keys.create.xpub

ChainAsset.create(alias: "disapproval", quorum: 2, keys: [asset_key, asset_key2])

ChainAsset.skip_callback(:create, :after, :create_chain_asset)

ChainAsset.create(alias: "facebook")
ChainAsset.create(alias: "instagram")
ChainAsset.create(alias: "phone_number")
ChainAsset.create(alias: "email")
ChainAsset.create(alias: "linked_in")

ChainAsset.set_callback(:create, :after, :create_chain_asset)

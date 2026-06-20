class CreateIdentities < ActiveRecord::Migration[8.0]
  def change
    create_table :identities do |t|
      t.references :user, null: false, foreign_key: true

      # (provider, external_id) is the login method. `password` ships now and
      # carries a digest; `google` slots in later as a new row — no migration
      # needed (ADR-0014). password_digest is null for non-password providers.
      t.string :provider, null: false
      t.string :external_id, null: false
      t.string :password_digest

      t.timestamps
    end

    # One identity per (provider, external_id): a username/email is claimed once.
    add_index :identities, [ :provider, :external_id ], unique: true
  end
end

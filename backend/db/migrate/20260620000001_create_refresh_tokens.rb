class CreateRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true

      # Only the SHA-256 digest of the opaque token is stored: a database leak
      # never exposes a usable refresh token (mirrors password_digest, ADR-0014).
      t.string :token_digest, null: false

      t.datetime :expires_at, null: false
      # Set when the token is rotated (on refresh) or revoked (on logout).
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :refresh_tokens, :token_digest, unique: true
  end
end

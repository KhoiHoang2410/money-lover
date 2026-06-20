class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      # Timezone defines month boundaries, monthly resets, and "today" for
      # Signals (ADR-0014). Defaults to the app's base-currency locale.
      t.string :timezone, null: false, default: "Asia/Ho_Chi_Minh"

      t.timestamps
    end
  end
end

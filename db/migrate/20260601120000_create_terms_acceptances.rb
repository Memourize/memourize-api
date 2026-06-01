class CreateTermsAcceptances < ActiveRecord::Migration[8.0]
  def change
    create_table :terms_acceptances do |t|
      t.references :user, null: false, foreign_key: true
      t.string :version, null: false
      t.datetime :accepted_at, null: false
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :terms_acceptances, [ :user_id, :version ]
  end
end

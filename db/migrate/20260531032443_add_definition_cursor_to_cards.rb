class AddDefinitionCursorToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :definition_cursor, :integer, null: false, default: 0
  end
end

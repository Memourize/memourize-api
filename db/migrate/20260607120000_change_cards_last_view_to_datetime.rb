class ChangeCardsLastViewToDatetime < ActiveRecord::Migration[8.0]
  def up
    change_column :cards, :last_view, :datetime
  end

  def down
    change_column :cards, :last_view, :date
  end
end

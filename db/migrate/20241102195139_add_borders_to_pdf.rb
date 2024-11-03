class AddBordersToPdf < ActiveRecord::Migration[7.2]
  def change
    add_column :pdfs, :borders, :string
  end
end

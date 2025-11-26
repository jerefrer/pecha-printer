class AddTwoSidedFlippedToPdfs < ActiveRecord::Migration[7.2]
  def change
    add_column :pdfs, :two_sided_flipped, :boolean, default: true, null: false
  end
end

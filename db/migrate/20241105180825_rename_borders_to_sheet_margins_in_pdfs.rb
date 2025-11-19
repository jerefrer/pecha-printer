class RenameBordersToSheetMarginsInPdfs < ActiveRecord::Migration[7.2]
  def change
    rename_column :pdfs, :borders, :sheet_margins
  end
end

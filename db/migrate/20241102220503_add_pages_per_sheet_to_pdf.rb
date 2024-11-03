class AddPagesPerSheetToPdf < ActiveRecord::Migration[7.2]
  def up
    add_column :pdfs, :pages_per_sheet, :integer, default: 3
    Pdf.update_all(pages_per_sheet: 3)
  end

  def down
    remove_column :pdfs, :pages_per_sheet, :integer
  end
end

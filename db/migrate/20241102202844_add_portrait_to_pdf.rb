class AddPortraitToPdf < ActiveRecord::Migration[7.2]
  def up
    add_column :pdfs, :portrait, :boolean, default: false
    Pdf.update_all(portrait: false)
  end

  def remove
    remove_column :pdfs, :portrait, :boolean, default: false
  end
end

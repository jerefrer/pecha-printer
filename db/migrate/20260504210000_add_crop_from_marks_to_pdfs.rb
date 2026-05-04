class AddCropFromMarksToPdfs < ActiveRecord::Migration[7.2]
  def change
    add_column :pdfs, :crop_from_marks, :boolean, default: false, null: false
  end
end

class AddTokenToPdfs < ActiveRecord::Migration[7.2]
  def up
    add_column :pdfs, :token, :string

    # Backfill existing records
    Pdf.reset_column_information
    Pdf.find_each do |pdf|
      pdf.update_column(:token, SecureRandom.hex(6))
    end

    change_column_null :pdfs, :token, false
    add_index :pdfs, :token, unique: true
  end

  def down
    remove_index :pdfs, :token
    remove_column :pdfs, :token
  end
end

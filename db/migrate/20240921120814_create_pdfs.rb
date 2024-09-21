class CreatePdfs < ActiveRecord::Migration[7.2]
  def change
    create_table :pdfs do |t|
      t.string :file
      t.string :paper_size
      t.string :autoscale

      t.timestamps
    end
  end
end

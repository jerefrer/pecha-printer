class Pdf < ApplicationRecord
  mount_uploader :file, PdfFileUploader

  validates_presence_of :file
  validates :paper_size, presence: true, inclusion: { in: %w[A4 A3] }
  validates :pages_per_sheet, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :autoscale, presence: true, inclusion: { in: %w[none pdfjam podofo] }

  attr_accessor :border_mode,
                :border_all,
                :border_horizontal, :border_vertical,
                :border_left, :border_right, :border_top, :border_bottom

  validates :borders, format: { 
    with: /\A(\d+ ){3}\d+\z/,
    message: "4 space-separated numbers",
    allow_blank: true
  }
end

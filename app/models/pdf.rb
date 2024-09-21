class Pdf < ApplicationRecord
  mount_uploader :file, PdfFileUploader

  validates_presence_of :file
  validates :paper_size, presence: true, inclusion: { in: %w[A4 A3] }
  validates :autoscale, presence: true, inclusion: { in: %w[false pdfjam podofo] }
end

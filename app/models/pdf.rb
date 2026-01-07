class Pdf < ApplicationRecord
  mount_uploader :file, PdfFileUploader

  before_create :generate_token

  validates_presence_of :file
  validates :paper_size, presence: true, inclusion: { in: %w[A4 A3] }
  validates :pages_per_sheet, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :autoscale, presence: true, inclusion: { in: %w[none pdfjam podofo] }

  attr_accessor :sheet_margin_mode,
                :sheet_margin_all,
                :sheet_margin_horizontal, :sheet_margin_vertical,
                :sheet_margin_left, :sheet_margin_right, :sheet_margin_top, :sheet_margin_bottom

  validates :sheet_margins, format: {
    with: /\A(-?\d+\.?\d* ){3}-?\d+\.?\d*\z/,
    message: "4 space-separated numbers (can include decimals, negative values allowed)",
    allow_blank: true
  }

  # Use token instead of id in URLs
  def to_param
    token
  end

  private

  def generate_token
    self.token = SecureRandom.hex(6)
  end
end

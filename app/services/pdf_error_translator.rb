# Maps the (English-only) error messages raised by the stacked-pdf-generator gem
# to friendly, localized messages for end users. Unknown messages fall back to a
# generic localized wrapper that still surfaces the raw technical detail.
module PdfErrorTranslator
  module_function

  def call(raw_message)
    message = raw_message.to_s

    case message
    when /Expected \d+ Y-rows of crop marks/
      I18n.t("pdf.errors.crop_marks_count")
    when /Crop mark row at y=.* is missing/
      I18n.t("pdf.errors.crop_row_incomplete")
    when /No crop marks detected/
      I18n.t("pdf.errors.no_crop_marks")
    when /PDF has no pages/, /Unable to determine page count/
      I18n.t("pdf.errors.no_pages")
    when /\A(pdfjam|podofocrop|pdfinfo) failed/
      I18n.t("pdf.errors.tool_failed", detail: message)
    else
      I18n.t("pdf.errors.generic", detail: message)
    end
  end
end

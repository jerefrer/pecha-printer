require "stacked_pdf_generator"

class PdfsController < ApplicationController
  def new
    @pdf = params[:id] ? find_pdf : Pdf.new(paper_size: "A4", pages_per_sheet: 3, autoscale: "pdfjam")
  end

  def create
    @pdf = Pdf.new(pdf_params)
    if @pdf.save
      result = process_pdf(@pdf)
      if result.success?
        redirect_to [ :edit, @pdf ]
        flash[:notice] = "PDF processed successfully!"
      else
        flash[:alert] = "Error processing PDF: #{result.message}"
        redirect_to root_path
      end
    else
      flash[:alert] = "Failed to upload PDF"
      redirect_to root_path
    end
  end

  def update
    @pdf = find_pdf
    if @pdf.update(pdf_params)
      result = process_pdf(@pdf)
      if result.success?
        redirect_to [ :edit, @pdf ]
        flash[:notice] = "PDF reprocessed successfully!"
      else
        flash[:alert] = "Error processing PDF: #{result.message}"
        redirect_to root_path
      end
    else
      flash[:alert] = "Wrong arguments"
      redirect_to root_path
    end
  end

  def download
    @pdf = find_pdf
    send_file output_file_path(@pdf), type: "application/pdf", disposition: "inline"
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "PDF not found"
    redirect_to root_path
  rescue Errno::ENOENT
    flash[:alert] = "File not found"
    redirect_to root_path
  end

  private

  def find_pdf
    Pdf.find_by!(token: params[:id])
  end

  def pdf_params
    permitted = params.require(:pdf).permit(
      :file, :pages_per_sheet, :paper_size, :portrait, :pages_per_sheet, :autoscale, :sheet_margins,
      :two_sided_flipped
    )

    # Clean up any empty border values
    permitted[:sheet_margins]&.strip!
    permitted[:sheet_margins] = nil if permitted[:sheet_margins].blank?

    permitted
  end

  def process_pdf(pdf)
    StackedPdfGenerator.call(
      input_path: pdf.file.path,
      output_path: output_file_path(pdf),
      pages_per_sheet: pdf.pages_per_sheet,
      paper_size: pdf.paper_size,
      autoscale: pdf.autoscale,
      portrait: pdf.portrait,
      sheet_margins: pdf.sheet_margins,
      two_sided_flipped: pdf.two_sided_flipped
    )
  end

  def output_file_name(pdf)
    pdf.file.file.filename.gsub(/\.pdf\z/, new_extension(pdf))
  end

  def output_file_path(pdf)
    pdf.file.path.gsub(/\.pdf\z/, new_extension(pdf))
  end

  def new_extension(pdf)
    "___FOR_PRINTING_ON_#{pdf.paper_size}.pdf"
  end
end

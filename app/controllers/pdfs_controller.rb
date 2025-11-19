require "open3"

class PdfsController < ApplicationController
  def new
    @pdf = params[:id] ? Pdf.find(params[:id]) : Pdf.new(paper_size: "A4", pages_per_sheet: 3, autoscale: "pdfjam")
  end

  def create
    @pdf = Pdf.new(pdf_params)
    if @pdf.save
      errors = process_pdf(@pdf)
      if errors.empty?
        redirect_to [ :edit, @pdf ]
        flash[:notice] = "PDF processed successfully!"
      else
        flash[:alert] = "Error processing PDF: #{errors}"
        redirect_to root_path
      end
    else
      flash[:alert] = "Failed to upload PDF"
      redirect_to root_path
    end
  end

  def update
    @pdf = Pdf.find(params[:id])
    if @pdf.update(pdf_params)
      errors = process_pdf(@pdf)
      if errors.empty?
        redirect_to [ :edit, @pdf ]
        flash[:notice] = "PDF reprocessed successfully!"
      else
        flash[:alert] = "Error processing PDF: #{errors}"
        redirect_to root_path
      end
    else
      flash[:alert] = "Wrong arguments"
      redirect_to root_path
    end
  end

  def download
    @pdf = Pdf.find(params[:id])
    send_file output_file_path(@pdf), type: "application/pdf", disposition: "inline"
  rescue
    flash[:alert] = "File not found"
    redirect_to root_path
  end

  private

  def pdf_params
    permitted = params.require(:pdf).permit(
      :file, :pages_per_sheet, :paper_size, :portrait, :pages_per_sheet, :autoscale, :sheet_margins
    )

    # Clean up any empty border values
    permitted[:sheet_margins]&.strip!
    permitted[:sheet_margins] = nil if permitted[:sheet_margins].blank?

    permitted
  end

  def process_pdf(pdf)
    script_path = Rails.root.join("lib/generate-printable-pecha/generate_printable_pecha.command")
    command_parts = [
      "python3",
      script_path,
      pdf.file.path,
      "--output-file-name", output_file_name(pdf),
      "--pages-per-sheet", pdf.pages_per_sheet,
      "--paper-size", pdf.paper_size,
      "--autoscale", pdf.autoscale
    ]

    command_parts << "--portrait" if pdf.portrait == true
    command_parts << "--sheet-margins" << %Q("#{pdf.sheet_margins}") if pdf.sheet_margins

    python_command = command_parts.join(" ")
    logger.info "Running command: #{python_command}"

    _, stderr, _ = Open3.capture3(python_command)
    stderr
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

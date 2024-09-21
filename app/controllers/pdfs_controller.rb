require "open3"

class PdfsController < ApplicationController
  def new
    @pdf = params[:id] ? Pdf.find(params[:id]) : Pdf.new
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
    params.require(:pdf).permit(:file, :paper_size, :autoscale)
  end

  def process_pdf(pdf)
    input_file_path = pdf.file.path
    paper_size = pdf_params[:paper_size]
    autoscale = pdf_params[:autoscale]

    script_path = Rails.root.join("lib/generate-printable-pecha/generate_printable_pecha.command")
    python_command = "python3 #{script_path} #{input_file_path} --paper-size #{paper_size} --autoscale #{autoscale} --output-name #{output_file_name(pdf)}"
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

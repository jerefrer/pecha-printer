namespace :pdfs do
  desc "Delete PDFs older than 1 hour along with their uploaded and processed files"
  task cleanup: :environment do
    old_pdfs = Pdf.where("created_at < ?", 1.hour.ago)
    count = old_pdfs.count

    old_pdfs.find_each do |pdf|
      # Delete processed output files (not tracked by CarrierWave)
      if pdf.file.present? && pdf.file.path.present?
        processed_file_pattern = pdf.file.path.gsub(/\.pdf\z/, "___FOR_PRINTING_ON_*.pdf")
        Dir.glob(processed_file_pattern).each do |processed_file|
          FileUtils.rm_f(processed_file)
        end
      end

      # CarrierWave will automatically delete the original file when the record is destroyed
      pdf.destroy
    end

    puts "[#{Time.current}] Cleaned up #{count} old PDF(s)" if count > 0
  end
end

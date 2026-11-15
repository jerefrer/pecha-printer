require "test_helper"

class PdfGenerationTest < ActionDispatch::IntegrationTest
  REQUIRED_TOOLS = %w[pdfjam pdfinfo podofocrop].freeze

  PRESETS = {
    standard_a4: {
      paper_size: "A4", portrait: "false", pages_per_sheet: "3", autoscale: "pdfjam",
      two_sided_flipped: "1", crop_from_marks: "0", sheet_margins: "0 -5 0 -5"
    },
    standard_a3: {
      paper_size: "A3", portrait: "false", pages_per_sheet: "3", autoscale: "pdfjam",
      two_sided_flipped: "1", crop_from_marks: "0", sheet_margins: "0 -5 0 -5"
    },
    shechen: {
      paper_size: "A3", portrait: "false", pages_per_sheet: "3", autoscale: "none",
      two_sided_flipped: "1", crop_from_marks: "1", sheet_margins: "0 0 0 0"
    }
  }.freeze

  setup do
    missing = REQUIRED_TOOLS.reject { |tool| system("which", tool, out: File::NULL, err: File::NULL) }
    skip "PDF tools not installed (#{missing.join(', ')}); install texlive-extra-utils, poppler-utils and podofo-utils" if missing.any?
  end

  test "should render the home page when visiting the root" do
    get root_path

    assert_response :success
    assert_select "h1", "Pecha Printer"
  end

  test "should show French copy when the locale param is fr" do
    get root_path(locale: "fr")

    assert_response :success
    assert_select "p", /Génère un PDF prêt à imprimer/
    assert_select "button.btn-primary", /Générer/
  end

  test "should keep the French locale on later requests when it was chosen once" do
    get root_path(locale: "fr")
    get root_path

    assert_select "p", /Génère un PDF prêt à imprimer/
  end

  test "should ignore an unknown locale when the param is not available" do
    get root_path(locale: "xx")

    assert_response :success
    assert_select "button.btn-primary", /Generate/
  end

  %i[standard_a4 standard_a3].each do |preset|
    test "should produce a downloadable PDF when using the #{preset} preset" do
      upload_pdf("sample.pdf", PRESETS.fetch(preset))

      assert_generated(preset == :standard_a4 ? "A4" : "A3")
    end
  end

  test "should produce a downloadable PDF when using the shechen preset with crop marks" do
    upload_pdf("sample_crop_marks.pdf", PRESETS.fetch(:shechen))

    assert_generated("A3")
  end

  test "should show the translated error when the shechen preset gets a PDF without crop marks" do
    upload_pdf("sample.pdf", PRESETS.fetch(:shechen))

    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=alert]", /No crop marks were detected/
  end

  test "should show the translated error in French when the locale is fr" do
    get root_path(locale: "fr")
    upload_pdf("sample.pdf", PRESETS.fetch(:shechen))
    follow_redirect!

    assert_select "[role=alert]", /Aucune marque de coupe détectée/
  end

  %w[A4 A3].each do |paper|
    [ "false", "true" ].each do |portrait|
      test "should generate without error when paper is #{paper} and portrait is #{portrait}" do
        upload_pdf("sample.pdf", PRESETS[:standard_a4].merge(paper_size: paper, portrait: portrait))

        assert_generated(paper)
      end
    end
  end

  (2..8).each do |count|
    test "should generate without error when pages per sheet is #{count}" do
      upload_pdf("sample.pdf", PRESETS[:standard_a4].merge(pages_per_sheet: count.to_s))

      assert_generated("A4")
    end
  end

  %w[none pdfjam podofo].each do |mode|
    test "should generate without error when autoscale is #{mode}" do
      upload_pdf("sample.pdf", PRESETS[:standard_a4].merge(autoscale: mode))

      assert_generated("A4")
    end
  end

  {
    "no margins" => "0 0 0 0",
    "the same margin on all sides" => "5 5 5 5",
    "horizontal and vertical margins" => "0 -5 0 -5",
    "custom decimal margins" => "1.5 2 -3.25 4",
    "blank margins" => ""
  }.each do |label, margins|
    test "should generate without error when using #{label}" do
      upload_pdf("sample.pdf", PRESETS[:standard_a4].merge(sheet_margins: margins))

      assert_generated("A4")
    end
  end

  [ "0", "1" ].each do |flag|
    test "should generate without error when two_sided_flipped is #{flag}" do
      upload_pdf("sample.pdf", PRESETS[:standard_a4].merge(two_sided_flipped: flag))

      assert_generated("A4")
    end
  end

  test "should regenerate with the new options when updating an existing PDF" do
    upload_pdf("sample.pdf", PRESETS.fetch(:standard_a4))
    pdf = Pdf.last

    patch pdf_path(pdf), params: { pdf: PRESETS.fetch(:standard_a3) }

    assert_redirected_to edit_pdf_path(pdf)
    follow_redirect!
    assert_select "[role=status]", /regenerated successfully/
    assert_equal "A3", pdf.reload.paper_size
    assert_downloadable(pdf)
  end

  test "should show the regenerate button when editing an existing PDF" do
    upload_pdf("sample.pdf", PRESETS.fetch(:standard_a4))
    follow_redirect!

    assert_select "input[type=submit][value*='Re-generate']"
    assert_select "embed[type='application/pdf']"
  end

  test "should show an error and keep the PDF when regenerating with invalid options" do
    upload_pdf("sample.pdf", PRESETS.fetch(:standard_a4))
    pdf = Pdf.last

    patch pdf_path(pdf), params: { pdf: { pages_per_sheet: "0" } }

    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=alert]", /Invalid options/
  end

  test "should redirect with an error when no file is uploaded" do
    assert_no_difference "Pdf.count" do
      post pdfs_path, params: { pdf: PRESETS.fetch(:standard_a4) }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=alert]", /could not be uploaded/
  end

  test "should redirect with an error when downloading an unknown token" do
    get download_pdf_path("doesnotexist")

    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=alert]", /PDF not found/
  end

  test "should redirect with an error when editing an unknown token" do
    get edit_pdf_path("doesnotexist")

    assert_redirected_to root_path
  end

  private

  def upload_pdf(fixture, options)
    file = fixture_file_upload(fixture, "application/pdf")
    post pdfs_path, params: { pdf: options.merge(file: file) }
  end

  def assert_generated(paper)
    assert_redirected_to edit_pdf_path(Pdf.last)
    follow_redirect!
    assert_select "[role=status]", /generated successfully/
    assert_equal paper, Pdf.last.paper_size
    assert_downloadable(Pdf.last)
  end

  def assert_downloadable(pdf)
    get download_pdf_path(pdf)

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF"), "download should be a PDF"
  end
end

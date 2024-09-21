require "test_helper"

class PdfProcessorControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get pdf_processor_index_url
    assert_response :success
  end

  test "should get process" do
    get pdf_processor_process_url
    assert_response :success
  end
end

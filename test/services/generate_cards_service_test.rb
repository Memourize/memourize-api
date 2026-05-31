require "test_helper"

class GenerateCardsServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(full_name: "A", email: "svc@example.com", password: "password")
    @file = uploaded_pdf_stub
  end

  # Builds a Groq-shaped response whose message content is the given JSON string.
  def groq_response_with(content_json)
    { "choices" => [ { "message" => { "content" => content_json } } ] }
  end

  # Minimal stand-in for an uploaded file the service accepts (PDF mime).
  def uploaded_pdf_stub
    file = Object.new
    def file.original_filename = "notes.pdf"
    def file.content_type = "application/pdf"
    def file.size = 1234
    def file.read = "binary"
    file
  end

  def run_service_with(content_json)
    service = GenerateCardsService.new(user: @user, file: @file, deck_name: "Deck")
    response = groq_response_with(content_json)
    # Skip real text extraction and real HTTP; feed the AI reply directly.
    service.define_singleton_method(:save_temp_file) { @tmp_path = nil }
    service.define_singleton_method(:extract_text_from_file) { "content" }
    service.define_singleton_method(:cleanup_tmp_file) { nil }
    service.define_singleton_method(:send_to_groq) { |_content| response }
    service.call
  end

  test "creates alternative definitions from the alternatives field" do
    json = [
      { term: "T1", definition: "D1", alternatives: [ "A1a", "A1b" ] }
    ].to_json

    result = run_service_with(json)
    assert result[:success], result[:error]

    card = result[:cards].first
    alts = card.alternative_definitions.order(:position)
    assert_equal [ "A1a", "A1b" ], alts.map(&:content)
    assert_equal [ 1, 2 ], alts.map(&:position)
  end

  test "creates a card with no alternatives when the field is missing" do
    json = [ { term: "T1", definition: "D1" } ].to_json

    result = run_service_with(json)
    assert result[:success], result[:error]
    assert_equal 0, result[:cards].first.alternative_definitions.count
  end

  test "ignores blank and non-array alternatives without failing" do
    json = [
      { term: "T1", definition: "D1", alternatives: [ "A1", "", "  " ] },
      { term: "T2", definition: "D2", alternatives: "not an array" }
    ].to_json

    result = run_service_with(json)
    assert result[:success], result[:error]

    t1 = result[:cards].find { |c| c.term == "T1" }
    t2 = result[:cards].find { |c| c.term == "T2" }
    assert_equal [ "A1" ], t1.alternative_definitions.order(:position).map(&:content)
    assert_equal 0, t2.alternative_definitions.count
  end
end

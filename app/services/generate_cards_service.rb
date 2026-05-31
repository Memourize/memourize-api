# app/services/groq/generate_cards_service.rb
require "net/http"
require "json"
require "securerandom"

begin
  require "pdf/reader"
rescue LoadError
  Rails.logger.warn("Gem 'pdf-reader' não instalada. Extração de PDF não funcionará.")
end

begin
  require "docx"
rescue LoadError
  Rails.logger.warn("Gem 'docx' não instalada. Extração de DOCX não funcionará.")
end

class GenerateCardsService
  ALLOWED_MIME_TYPES = %w[
    application/pdf
    text/plain
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze

  # Limite de segurança para os caracteres que enviaremos para a IA (contexto + prompt)
  # O modelo 'llama-3.1-8b-instant' tem 131k tokens, mas vamos ser conservadores.
  MAX_CONTENT_LENGTH = 100_000 # 100 mil caracteres

  ALTERNATIVES_PER_CARD = 2 # ajustável; conservador para o modelo gratuito

  def initialize(user:, file:, deck_name: nil)
    @user = user
    @file = file
    @deck_name = deck_name.presence || "Deck gerado por IA"
    @tmp_path = nil
  end

  def call
    validate!

    # Cria o deck primeiro
    @deck = @user.decks.create!(name: @deck_name)

    save_temp_file

    # Esta é a grande mudança: extraímos o texto ou falhamos
    content = extract_text_from_file

    # Trunca o conteúdo se for muito longo
    if content.length > MAX_CONTENT_LENGTH
      content = content[0...MAX_CONTENT_LENGTH]
      Rails.logger.warn("Conteúdo do arquivo truncado para #{MAX_CONTENT_LENGTH} caracteres.")
    end

    ai_response = send_to_groq(content)
    ai_text = parse_groq_response(ai_response)

    cards_data = extract_json_array(ai_text)
    raise "Resposta inválida da IA (JSON ausente ou incorreto)" unless cards_data.is_a?(Array)

    created_cards = create_cards(cards_data)

    { success: true, deck: @deck, cards: created_cards }
  rescue => e
    # Se algo der errado, destruímos o deck vazio que foi criado
    @deck.destroy if @deck&.persisted?
    { success: false, error: e.message }
  ensure
    cleanup_tmp_file
  end

  private

  def validate!
    raise "Usuário inválido" unless @user
    raise "Arquivo inválido" unless @file.respond_to?(:original_filename)

    unless ALLOWED_MIME_TYPES.include?(@file.content_type)
      raise "Tipo de arquivo não suportado (#{@file.content_type}). Apenas PDF, TXT ou DOCX são aceitos."
    end
  end

  def save_temp_file
    filename = "#{SecureRandom.uuid}_#{@file.original_filename}"
    @tmp_path = Rails.root.join("tmp", filename)
    # Abre o arquivo em modo binário para escrita
    File.open(@tmp_path, "wb") { |f| f.write(@file.read) }
  end

  # ------ GRANDE MUDANÇA AQUI ------
  # Removemos o fallback para base64. Ou extrai texto, ou falha.
  def extract_text_from_file
    case @file.content_type
    when "application/pdf"
      raise "Gem 'pdf-reader' não está instalada." unless defined?(PDF::Reader)
      extract_text_from_pdf(@tmp_path)
    when "text/plain"
      File.read(@tmp_path)
    when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      raise "Gem 'docx' não está instalada." unless defined?(Docx)
      extract_text_from_docx(@tmp_path)
    else
      raise "Tipo de arquivo não suportado para extração: #{@file.content_type}"
    end
  rescue => e
    Rails.logger.error("Falha ao extrair texto: #{e.message}")
    raise "Não foi possível ler o conteúdo do arquivo. Ele pode estar corrompido ou ser uma imagem."
  end
  # ------ FIM DA GRANDE MUDANÇA ------

  def extract_text_from_pdf(path)
    text = []
    PDF::Reader.open(path) do |reader|
      reader.pages.each { |page| text << page.text }
    end
    text.join("\n").strip
  end

  def extract_text_from_docx(path)
    doc = Docx::Document.open(path)
    doc.paragraphs.map(&:text).join("\n").strip
  end

  def send_to_groq(content_data)
    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{ENV['GROQ_API_KEY']}"
    }

    prompt_base = <<~PROMPT
      Você é um assistente que transforma conteúdo em flashcards de estudo.

      Gere **somente um JSON válido**, no formato:
      [
        {
          "term": "termo 1",
          "definition": "definição do termo 1",
          "alternatives": ["outra forma de explicar o termo 1", "mais uma visão do termo 1"]
        }
      ]

      - Gere entre 5 e 15 cards em português.
      - Termos curtos e diretos.
      - Definições claras e concisas (até ~300 caracteres).
      - Para cada card, gere #{ALTERNATIVES_PER_CARD} definições ALTERNATIVAS no campo "alternatives".
      - Cada alternativa deve explicar o MESMO conceito do "definition" com outras palavras
        ou outra abordagem (outra perspectiva), nunca um conceito diferente.
    PROMPT

    # O 'user_content' agora é sempre texto
    user_content = "Conteúdo extraído do arquivo:\n\n#{content_data}"

    body = {
      model: "llama-3.1-8b-instant", # O modelo que você encontrou
      messages: [
        { role: "system", content: prompt_base },
        { role: "user", content: user_content }
      ],
      temperature: 0.5,
      max_tokens: 4096 # acomoda as definições alternativas
    }

    response = Net::HTTP.post(uri, body.to_json, headers)
    raise "Erro HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def parse_groq_response(response_json)
    text = response_json.dig("choices", 0, "message", "content")
    raise "Resposta vazia da IA" if text.blank?
    text
  end

  def extract_json_array(text)
    # Tenta encontrar o JSON em qualquer lugar da resposta
    json_match = text.match(/(\[.*\])/m)&.captures&.first

    # Se não encontrar, talvez a IA tenha retornado SÓ o JSON
    if json_match.nil?
      begin
        parsed = JSON.parse(text)
        json_match = text if parsed.is_a?(Array)
      rescue JSON::ParserError
        # Não era um JSON válido
      end
    end

    raise "Não foi possível encontrar JSON na resposta da IA. Resposta: #{text}" unless json_match
    JSON.parse(json_match)
  end

  def create_cards(cards_data)
    cards_data.map do |card|
      next unless card["term"].present? && card["definition"].present? # Pula cards vazios
      new_card = @deck.cards.create!(
        term: card["term"].to_s.strip,
        definition: card["definition"].to_s.strip
      )
      create_alternative_definitions(new_card, card["alternatives"])
      new_card
    end.compact # Remove os nils
  end

  # Best-effort: alternatives never break card creation.
  def create_alternative_definitions(card, alternatives)
    return unless alternatives.is_a?(Array)

    position = 0
    alternatives.each do |content|
      text = content.to_s.strip
      next if text.empty?

      position += 1
      card.alternative_definitions.create!(content: text, position: position)
    end
  end

  def cleanup_tmp_file
    File.delete(@tmp_path) if @tmp_path && File.exist?(@tmp_path)
  end
end

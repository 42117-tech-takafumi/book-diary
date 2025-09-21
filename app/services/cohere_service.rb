require 'httparty'
require 'json'

class CohereService
  include HTTParty
  base_uri 'https://api.cohere.ai/v1'

  BASE_PROMPT = "以下の本を読んだ人へお薦めの実在する小説を20冊教えてください。
    実在する本だけお薦めしてください。
    タイトルと著者名だけ返してください。
    返答は日本語でお願いします。               
    返すときは「タイトル,著者名,タイトル,著者名・・・」といった形式で返してください。これ以外の文字などは含めないでください。
    下記の本はお薦めとしては選ばないで下さい。"

  def initialize
    @headers = {
      "Authorization" => "Bearer #{ENV['COHERE_API_KEY']}",
      "Content-Type" => "application/json"
    }
  end

  def search_books_by_ai(title_authors)
    #検索テキストに読書履歴の本は検索しないようにする
    prompt = BASE_PROMPT + title_authors

    body = {
      model: "command-r-plus-08-2024",
      message: prompt,
      temperature: 0.3,
      return_chatlog: false
    }

    response = self.class.post("/chat", headers: @headers, body: body.to_json, timeout: 40)
    
    #念のため大文字「，」を小文字に変換
    books_text = response.parsed_response["text"].gsub("，", ",")
    
    books_list = books_text.split("\n").map do |line|
      _number, rest = line.split(". ", 2)   # 先頭の番号を捨てる
      title, author = rest.split(",", 2)    # タイトルと著者に分割
      { title: title.strip, author: author.strip }
    end

    return rank_books_by_similarity(title_authors, books_list)

  end

  private

  def embed_texts(texts)
    body = {
      model: "embed-english-v3.0",
      texts: texts,
      input_type: "classification"
    }

    response = self.class.post("/embed", headers: @headers, body: body.to_json, timeout: 40)
    response.parsed_response["embeddings"]

  end

  def rank_books_by_similarity(title_authors, books_list)
    input_embedding = embed_texts([title_authors]).first
    book_embeddings = embed_texts(books_list.map { |b| "#{b[:title]} #{b[:author]}" })
  
    ranked = books_list.zip(book_embeddings).map do |book, emb|
      score = cosine_similarity(input_embedding, emb)
      { book: book, similarity: score }
    end
  
    # 類似度順にソートし、上位7冊のタイトルと著者を交互に並べた1次元配列として返す
    ranked.sort_by { |b| -b[:similarity] }
          .first(7)
          .flat_map { |item| [item[:book][:title], item[:book][:author]] }
  end

  def cosine_similarity(vec1, vec2)
    dot = vec1.zip(vec2).map { |a, b| a * b }.sum
    norm1 = Math.sqrt(vec1.map { |x| x**2 }.sum)
    norm2 = Math.sqrt(vec2.map { |x| x**2 }.sum)
    dot / (norm1 * norm2)
  end

end
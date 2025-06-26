require 'httparty'

class CohereService
  include HTTParty
  base_uri 'https://api.cohere.ai/v1'

  #検索テキスト
  BASE_PROMPT = "以下の本を読んだ人へお薦めの実在する小説を7冊教えてください。
            実在する本だけお薦めしてください。
            タイトルと著者名だけ返してください。
            返答は日本語でお願いします。              
            返すときは「タイトル,著者名,タイトル,著者名,・・・」といった形式で返してください。これ以外の文字などは含めないでください。
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
      model: "command-r-plus",
      message: prompt,
      temperature: 0.3,
      return_chatlog: false
    }

    response = self.class.post("/chat", headers: @headers, body: body.to_json, timeout: 40)
    books = response.parsed_response["text"].gsub("，",",") #念のため大文字「，」を小文字に変換
    @books = books.split(',')
    @books = @books.each_slice(2).to_a

  end
end

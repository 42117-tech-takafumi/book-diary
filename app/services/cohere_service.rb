require 'httparty'

class CohereService
  include HTTParty
  base_uri 'https://api.cohere.ai/v1'

  def initialize
    @headers = {
      "Authorization" => "Bearer #{ENV['COHERE_API_KEY']}",
      "Content-Type" => "application/json"
    }
  end

  def search_books_by_ai(prompt)
    body = {
      model: "command-r-plus",
      message: prompt,
      temperature: 0.3,
      return_chatlog: false
    }

    response = self.class.post("/chat", headers: @headers, body: body.to_json, timeout: 40)
    response.parsed_response["text"]
  end
end

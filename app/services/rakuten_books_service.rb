require 'net/http'
require 'json'
require 'cgi'

class RakutenBooksService
  #本を検索する際のベースとなるURLとジャンルを検索する際のベースとなるURL
  BOOK_BASE_URL = "https://app.rakuten.co.jp/services/api/BooksBook/Search/20170404"
  GENRE_BASE_URL = "https://app.rakuten.co.jp/services/api/BooksGenre/Search/20121128?format=json&booksGenreId="

  #本を検索するメソッド
  def self.search_books(search_params)
    title_query = ""
    author_query = ""
    isbn_query = ""

    #渡された検索条件によって検索方法を分ける
    if search_params[:isbn_query].present?
      isbn_query = "&isbn=#{CGI.escape(search_params[:isbn_query])}"
    elsif search_params[:title_query].present? && search_params[:author_query].present?
      title_query = "&title=#{CGI.escape(search_params[:title_query])}"
      author_query = "&author=#{CGI.escape(search_params[:author_query])}"
    elsif search_params[:title_query].present?
      title_query = "&title=#{CGI.escape(search_params[:title_query])}"
    else
      author_query = "&author=#{CGI.escape(search_params[:author_query])}"
    end

    #入力された情報を元に本を検索し、返ってきたデータをJSON形式で受け取る
    query = "#{BOOK_BASE_URL}?format=json#{title_query}#{author_query}#{isbn_query}&page=#{search_params[:page]}&applicationId=#{ENV['RAKUTEN_APP_ID']}"
    url = URI(query)
    response = Net::HTTP.get(url)
    parsed_response = JSON.parse(response) 

    # 全ヒット件数を取得
    total_hits = parsed_response["count"] || parsed_response["hits"]
    page = parsed_response["page"].to_i
    total_pages = (total_hits.to_i/30).ceil + 1
    books = JSON.parse(response)["Items"] || []
    return books,total_hits,page,total_pages

  end

  #本のジャンルを検索するメソッド
  def self.search_genres(books)
    books.each do |book|
      
      book_genres = book["Item"]["booksGenreId"]
      genre_name = ""

      #ジャンルidが振られていたらジャンルを検索する
      if book_genres.present?
        #ジャンルidから半角数字と/以外の文字列を削除
        book_genres = book_genres.gsub(/[^0-9\/]/, "")

        #ジャンルidを/で区切る
        book_genres = book_genres.split("/")

        book_genres.each do |book_genre|
          url = URI("#{GENRE_BASE_URL}#{CGI.escape(book_genre)}&applicationId=#{ENV['RAKUTEN_APP_ID']}")
          response = Net::HTTP.get(url)

          unless genre_name.blank?
            genre_name = genre_name + "、"
          end

          genre_name = genre_name + JSON.parse(response)["current"]["booksGenreName"]
          
        end

      else

        genre_name = "ジャンル無し"

      end

      book["Item"]["booksGenreName"] = genre_name

    end

    return books
  end

end
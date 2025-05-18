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
    query = "#{BOOK_BASE_URL}?format=json#{title_query}#{author_query}#{isbn_query}&page=#{search_params[:page]}&sort=reviewCount&applicationId=#{ENV['RAKUTEN_APP_ID']}"
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

  #読書履歴からお薦めの本を検索するメソッド
  def self.search_recommended_books(most_frequent_my_genre,most_frequent_author)
    #ファンタジーのキーワードリスト
    fantasy_keywords = ["ファンタジー","魔法", "勇者", "ドラゴン", "異世界", "精霊", "呪文", "魔王", "魔導", "剣士", "魔女"]
    author_query = "&author=#{CGI.escape(most_frequent_author)}"
    genre_query = "&booksGenreId=#{CGI.escape(most_frequent_my_genre)}"

    #著者のお薦め本を検索
    query = "#{BOOK_BASE_URL}?format=json#{author_query}&sort=reviewCount&applicationId=#{ENV['RAKUTEN_APP_ID']}"
    url = URI(query)
    response = Net::HTTP.get(url)
    author_books = JSON.parse(response)["Items"] || []

    #ジャンルのお薦め本を検索
    query = "#{BOOK_BASE_URL}?format=json#{genre_query}&sort=reviewCount&applicationId=#{ENV['RAKUTEN_APP_ID']}"
    url = URI(query)
    response = Net::HTTP.get(url)
    parsed_response = JSON.parse(response) 
    genre_books = JSON.parse(response)["Items"] || []

    #ジャンルがファンタジーの場合
    if most_frequent_my_genre == "001003001"
      total_hits = parsed_response["count"] || parsed_response["hits"]
      total_pages = (total_hits.to_i/30).ceil

      genre_books = ""

      total_pages.times do |cnt|
        cnt += 1

        query = "#{BOOK_BASE_URL}?format=json#{genre_query}&page=#{cnt}&sort=reviewCount&applicationId=#{ENV['RAKUTEN_APP_ID']}"
        url = URI(query)
        response = Net::HTTP.get(url)
        parsed_response = JSON.parse(response) 
        fantasy_books = JSON.parse(response)["Items"] || []

        sleep(0.5)

        fantasy_books.each do |book|
          item_caption = book["Item"]["itemCaption"] || ""
          if fantasy_keywords.any? { |word| item_caption.include?(word) }
            if genre_books.blank?
              genre_books = [book]
            else
              genre_books << book
            end
          end
        end

        if genre_books.length > 5
          break
        end
      end
    end
    
    return author_books,genre_books
  end

  def self.search_recommended_books_by_ai(books)

    search_books=""

    (books.length/2).times do|i|
      i *= 2
      title_query = "&title=#{CGI.escape(books[i])}"
      author_query = "&author=#{CGI.escape(books[i+1])}"

      #入力された情報を元に本を検索し、返ってきたデータをJSON形式で受け取る
      query = "#{BOOK_BASE_URL}?format=json#{title_query}#{author_query}&hits=1&sort=reviewCount&applicationId=#{ENV['RAKUTEN_APP_ID']}"
      url = URI(query)
      response = Net::HTTP.get(url)
      book = JSON.parse(response)["Items"] || []

      #ヒットしなかったらタイトルのみで検索しなおす
      if book.blank?
        query = "#{BOOK_BASE_URL}?format=json#{title_query}&hits=1&sort=reviewCount&applicationId=#{ENV['RAKUTEN_APP_ID']}"
        url = URI(query)
        response = Net::HTTP.get(url)
        book = JSON.parse(response)["Items"] || []
      end

      sleep(0.5)

      if search_books.blank? && !book.blank?
        search_books = book
      elsif !book.blank?
        search_books << book[0]
      end
      
    end

    return search_books

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
          
          #ジャンル検索が失敗ではない場合、変数にジャンル名を格納する
          unless response.include?("error_description")
            genre_name = genre_name + JSON.parse(response)["current"]["booksGenreName"]
          else
            genre_name = "ジャンル無し"
          end
          
        end

      else

        genre_name = "ジャンル無し"

      end

      book["Item"]["booksGenreName"] = genre_name

    end

    return books
  end

end
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

  #AIの検索結果から該当する本を検索するメソッド
  def self.search_recommended_books_by_ai(books)

    search_books=""

    books.each do |title, author|
      title_query = "&title=#{CGI.escape(title)}"
      author_query = "&author=#{CGI.escape(author)}"

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
    genre_id_set = Set.new  #重複無しでジャンルIDを格納するためのset型オブジェクト
    genre_cache = {}        #キャッシュ用のハッシュ
    thread_count = 5        #一度に検索する件数
    threads = []            #スレッド用配列
    mutex = Mutex.new       #排他ロック用オブジェクト（複数スレッドがキャッシュへ同時に書き込まないようにする）
  
    books.each do |book|
      book_genre = book["Item"]["booksGenreId"]
      
      if book_genre.present?
        book_ids = book_genre.gsub(/[^0-9\/]/, "").split("/")
        book_ids.each { |id| genre_id_set << id }
      end

    end
  
    #普通の配列にset型オブジェクトの値を格納（.each_sliceは普通の配列でしか使用できないため）
    genre_id_list = genre_id_set.to_a
  
    #スレッド1つにつき最大5件ずつジャンルIDを元にジャンル名をRakutenBooksAPIで検索
    genre_id_list.each_slice((genre_id_list.size / thread_count.to_f).ceil) do |ids_slice|
      threads << Thread.new do
        ids_slice.each do |genre_id|
          
          #ジャンルidがキャッシュに無かったらRakutenBooksAPIで検索し、新しくキャッシュに登録する
          genre_name = Rails.cache.fetch("genre_#{genre_id}", expires_in: 1.day) do
            url = URI("#{GENRE_BASE_URL}#{CGI.escape(genre_id)}&applicationId=#{ENV['RAKUTEN_APP_ID']}")
            response = Net::HTTP.get(url)
  
            if response.include?("error_description")
              "ジャンル無し"
            else
              JSON.parse(response)["current"]["booksGenreName"]
            end
            
          end
  
          #mutexで複数のスレッドが同時にキャッシュへ書き込むのを防止
          mutex.synchronize do
            genre_cache[genre_id] = genre_name
          end

        end
      end
    end
    
    #後続処理で不具合が起きないように全スレッドの処理が終わるのを待つ
    threads.each(&:join)
  
    #各本にジャンル名を紐づける
    books.each do |book|
      book_genre = book["Item"]["booksGenreId"]

      if book_genre.present?
        book_ids = book_genre.gsub(/[^0-9\/]/, "").split("/")
        genre_name = book_ids.map { |id| genre_cache[id] || "ジャンル無し" }.uniq.join("、")
      else
        genre_name = "ジャンル無し"
      end

      book["Item"]["booksGenreName"] = genre_name

    end
  
    return books

  end
  
end
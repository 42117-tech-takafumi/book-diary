class ReviewsController < ApplicationController
  before_action :authenticate_user! , only: [:new,:create,:edit,:recommend,:recommend_by_ai]
  before_action :set_search_params , only: [:new,:create]
  before_action :set_review , only: [:show,:edit,:update,:destroy]
  before_action :move_to_index, only: [:edit,:destroy,:show]
  before_action :search_review_isbn,  only: [:search]
  
  def index
    
  end

  def new
    
    @review = Review.new
    @review.title = params["title"]
    @review.image_url = params["largeImageUrl"]
    @review.author = params["author"]
    @review.publisher_name = params["publisherName"]
    @review.isbn = params["isbn"]
    @review.books_genre_id = params["booksGenreId"]
    @review.books_genre_name = params["booksGenreName"]
    @review.item_caption = params["itemCaption"]
    
  end

  def create
    
    @review = Review.new(review_params)

    if @review.save
      redirect_to user_path(current_user.id)
    else
      render :new, status: :unprocessable_entity
    end

  end
  
  def show
    
  end

  def edit

  end

  def update

    if @review.update(review_params)
      redirect_to user_path(current_user.id)
    else
      render :edit, status: :unprocessable_entity
    end

  end

  def destroy

    @review.destroy
    redirect_to user_path(current_user.id)

  end

  def search
    #検索条件を変数に格納
    @search_params = params
    
    #入力値に誤りがある場合はエラーメッセージを作成
    if @search_params[:title_query].blank? && @search_params[:author_query].blank? && @search_params[:isbn_query].blank?
      @error_message = "タイトル・著者・isbnのいずれかを入力してください"
    elsif @search_params[:isbn_query].present? && !@search_params[:isbn_query].match(/^\d{10}|\d{13}$/)
      @error_message = "isbnは10桁または13桁の半角数字で入力してください"
    else
      #本を検索する
      book_search = RakutenBooksService.search_books(@search_params) 
      @books = book_search[0]
      @book_counts = {total_hits:book_search[1],page:book_search[2],total_pages:book_search[3]}

      #本を検索出来たらジャンルを検索する
      if @books.present?
        @books = RakutenBooksService.search_genres(@books)
      end
    end
    
    render :index

  end

  def recommend
    #ユーザーが投稿した感想を全て取得
    @reviews = Review.where(user_id: current_user.id)

    #タグ、著者を抽出し、配列に格納
    all_tags = @reviews.pluck(:tag_id1, :tag_id2).flatten.compact
    all_authors = @reviews.pluck(:author).flatten.compact
    all_authors = all_authors.reject { |a| a.include?("著者無し") }.flat_map { |author| author.sub(/\/.*/, '') }

    #タグ、著者を数が多い順に並び替え
    tag_counts = all_tags.group_by(&:itself).transform_values(&:size).sort_by { |_, count| -count }
    most_frequent_tag = tag_counts[0][0]
    author_counts = all_authors.group_by { |author| author }.max_by { |author, occurrences| occurrences.size }
    @most_frequent_author = all_authors[0]

    #1番多いタグが1（デフォルト値）の場合は2番目に多いタグを探す
    if most_frequent_tag == 1 && tag_counts.length > 1
      most_frequent_tag = tag_counts[1][0]
    end

    #タグidを元に楽天ブックスのジャンルに変換
    @most_frequent_my_genre = set_genre(most_frequent_tag)

    #お薦めの本を検索し、既に読んだ本を取り除く
    book_search = RakutenBooksService.search_recommended_books(@most_frequent_my_genre,@most_frequent_author)
    @author_books = remove_book(book_search[0])
    @genre_books = remove_book(book_search[1])

    #本を検索出来たらジャンルを検索する
    @author_books = RakutenBooksService.search_genres(@author_books)
    @genre_books = RakutenBooksService.search_genres(@genre_books)

  end

  def recommend_by_ai
    #ユーザーが投稿した感想を全て取得
    @reviews = Review.where(user_id: current_user.id)

    #今で読んだ本のタイトルとその著者名
    title_authors = ""
    @reviews.each do |review|
      title_authors = title_authors + ("・タイトル：#{review.title}、著者：#{review.author}")
    end

    #CohereAPIで読書履歴からお薦め本を検索
    cohere_service = CohereService.new
    @books = cohere_service.search_books_by_ai(title_authors)

    #検索結果を配列に格納し、RakutenBooksAPIで検索
    @ai_books = RakutenBooksService.search_recommended_books_by_ai(@books)
    
    #本を検索出来たらジャンルを検索する
    @ai_books = RakutenBooksService.search_genres(@ai_books)

    render :recommend
    
  end

  private

  def review_params
    if params[:review].present?
      params.require(:review).permit(:title,:image_url,:author,:publisher_name,:isbn,:books_genre_id,:books_genre_name,:tag_id1,:tag_id2,:item_caption,:comment).merge(user_id: current_user.id)
    else
      filtered_params = params.except(:title_query, :author_query, :isbn_query, :page)
      filtered_params.permit(:title,:image_url,:author,:publisher_name,:isbn,:books_genre_id,:books_genre_name,:tag_id1,:tag_id2,:item_caption,:comment).merge(user_id: current_user.id)
    end
  end

  def set_review
    @review = Review.find(params[:id])
  end
  
  def set_search_params
    @search_params = {title_query:params[:title_query],author_query:params[:author_query],isbn_query:params[:isbn_query],page:params[:page] }
  end

  def set_genre(most_frequent_tag)
    most_frequent_my_genre = ""

    if most_frequent_tag == 2 #ミステリー・サスペンス
      most_frequent_my_genre = "001004001"
      @book_genre_name = "ミステリー・サスペンス"
    elsif most_frequent_tag == 3 #SF
      most_frequent_my_genre = "001004002"
      @book_genre_name = "SF"
    elsif most_frequent_tag == 4 #ホラー
      most_frequent_my_genre = "001004002"
      @book_genre_name = "ホラー"
    elsif most_frequent_tag == 5 #エッセイ
      most_frequent_my_genre = "001004003001"
       @book_genre_name = "エッセイ"
    elsif most_frequent_tag == 6 #ロマンス
      most_frequent_my_genre = "001004016"
      @book_genre_name = "ロマンス"
    elsif most_frequent_tag == 7 #ファンタジー
      most_frequent_my_genre = "001003001"
      @book_genre_name = "ファンタジー"
    elsif most_frequent_tag == 8 #ノンフィクション
      most_frequent_my_genre = "001004004001"
      @book_genre_name = "ノンフィクション"
    elsif most_frequent_tag == 9 #歴史
      most_frequent_my_genre = "001008005"
      @book_genre_name = "歴史"
    elsif most_frequent_tag == 10 #児童書
      most_frequent_my_genre = "001003001"
      @book_genre_name = "児童書"
    end

    return most_frequent_my_genre
  end

  def move_to_index
    if current_user != @review.user
      redirect_to action: :index
    end
  end

  def search_review_isbn
    @isbn_list = "a"
    if user_signed_in?
      user = User.find(current_user.id)
      @reviews = user.reviews
      @isbn_list = @reviews.pluck(:isbn).flatten.compact
      
      if @isbn_list.blank?
        @isbn_list = "a"
      end
    end
  end

  def remove_book(recommended_books)
    @reviews.each do |review|
      recommended_books.delete_if { |book| book["Item"]["isbn"] == review.isbn }
      recommended_books.delete_if { |book| book["Item"]["title"] == review.title }
    end

    return recommended_books
  end

end

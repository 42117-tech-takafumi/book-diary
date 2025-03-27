class ReviewsController < ApplicationController
  before_action :authenticate_user! , only: [:new,:create,:edit,:recommend]
  before_action :set_search_params , only: [:new,:create]
  before_action :set_review , only: [:show,:edit,:update,:destroy]
  before_action :move_to_index, only: [:edit,:destroy,:show]
  
  def index
    
  end

  def new
    
    @review = Review.new
    @review.title = params["book"]["Item"]["title"]
    @review.image_url = params["book"]["Item"]["largeImageUrl"]
    @review.author = params["book"]["Item"]["author"]
    @review.publisher_name = params["book"]["Item"]["publisherName"]
    @review.isbn = params["book"]["Item"]["isbn"]
    @review.books_genre_id = params["book"]["Item"]["booksGenreId"]
    @review.books_genre_name = params["book"]["Item"]["booksGenreName"]
    @review.item_caption = params["book"]["Item"]["itemCaption"]
    
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
      @error_message = "Please enter a value for either the Title, Author, or Isbn."
    elsif @search_params[:isbn_query].present? && !@search_params[:isbn_query].match(/^\d{10}|\d{13}$/)
      @error_message = "Isbn must be 10 or 13 digits of half-width numbers for the Isbn."
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
    all_authors = all_authors.flat_map { |author| author.sub(/\/.*/, '')   }

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

    book_search = RakutenBooksService.search_recommended_books(@most_frequent_my_genre,@most_frequent_author)
    @author_books = book_search[0]
    @genre_books = book_search[1]

    #本を検索出来たらジャンルを検索する
    @author_books = RakutenBooksService.search_genres(@author_books)
    @genre_books = RakutenBooksService.search_genres(@genre_books)

    #検索した本から既に読んだ本を取り除く
    @author_books = remove_book(@author_books)
    @genre_books = remove_book(@genre_books)

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
    end

    return most_frequent_my_genre
  end

  def move_to_index
    if current_user != @review.user
      redirect_to action: :index
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

class ReviewsController < ApplicationController
  before_action :authenticate_user! , only: [:new]
  before_action :set_search_params , only: [:new,:create]

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

  def create
    
    @review = Review.new(review_params)

    if @review.save
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def review_params
    filtered_params = params.except(:title_query, :author_query, :isbn_query, :page)
    filtered_params.permit(:title,:image_url,:author,:publisher_name,:isbn,:books_genre_id,:books_genre_name,:tag_id1,:tag_id2,:item_caption,:comment).merge(user_id: current_user.id)
  end

  def set_search_params
    @search_params = {title_query:params[:title_query],author_query:params[:author_query],isbn_query:params[:isbn_query],page:params[:page] }
  end

end

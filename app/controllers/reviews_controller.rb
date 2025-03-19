class ReviewsController < ApplicationController
  
  def index
    
  end

  def search
    #検索条件を変数に格納
    @search_params = params
    #binding.pry
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
end

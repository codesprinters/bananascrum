class NewsController < DomainBaseController
  verify :method => :post, :only => [ :dismiss_unread ]

  def dismiss_unread
    user = User.current.reload
    user.last_news_read_date = Time.current
    user.save

    latest_news = News.latest_for_plan(Domain.current.plan)
    if latest_news
      latest_news.increment(:read_count)
      latest_news.save
    end
    
    respond_to do |format|
      format.js { render_json :ok }
    end
  end

end

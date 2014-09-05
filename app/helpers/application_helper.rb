module ApplicationHelper

  #ページごとの完全なタイトルを返します。
  def full_title(page_title)
    base_title = "AST"
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  # 環境別にタイトルを変更します。
  def title_per_env(page_title)
    env = Rails.env
    if Rails.env.production?
      page_title
    else
      "#{page_title} | #{env}"
    end
  end
end

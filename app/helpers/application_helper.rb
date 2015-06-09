module ApplicationHelper

  def set_title(value)
    content_for(:title, value)

    wiselinks_title(value)
  end

  def full_title(page_title)
    base_title = "SiteGoal"
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end
end

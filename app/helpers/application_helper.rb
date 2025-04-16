module ApplicationHelper
  def page_title
    "#{@page_title || "Home" } - Crypto Portfolio"
  end

  def full_page_title
    if @page_title.present?
      "#{@page_title} - Crypto Portfolio"
    else
      "Crypto Portfolio API"
    end
  end

  def page_heading
    content_tag(:h1, page_title)
  end
end

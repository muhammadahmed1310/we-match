module ApplicationHelper
  def nav_link_active?(path)
    current_page?(path) || (path != root_path && request.path.start_with?(path.to_s))
  end

  def nav_link_class(path)
    classes = [ "nav-link" ]
    classes << "nav-link--active" if nav_link_active?(path)
    classes.join(" ")
  end
end

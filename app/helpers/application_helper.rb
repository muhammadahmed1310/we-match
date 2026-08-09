module ApplicationHelper
  def nav_link_active?(path)
    current_page?(path) || (path != root_path && request.path.start_with?(path.to_s))
  end

  def nav_link_class(path)
    classes = [ "nav-link" ]
    classes << "nav-link--active" if nav_link_active?(path)
    classes.join(" ")
  end

  def we_logo_image(variant: :dark, html_class: nil)
    filename = variant == :reverse ? "we-logo-reverse.png" : "we-logo.png"
    image_tag filename, alt: "Women Emerging", class: [ "we-logo", html_class ].compact.join(" ")
  end

  # IANA identifiers as values so the zone the browser reports can be selected and
  # saved without translation.
  def time_zone_options
    @time_zone_options ||= ActiveSupport::TimeZone.all.filter_map do |zone|
      identifier = ActiveSupport::TimeZone::MAPPING[zone.name]
      next if identifier.blank?

      [ "#{zone} — #{identifier}", identifier ]
    end.uniq { |_label, identifier| identifier }
  end

  def local_time(time, time_zone, format: "%b %-d, %Y %H:%M %Z")
    return "—" if time.blank?

    zone = ActiveSupport::TimeZone[time_zone.to_s] || ActiveSupport::TimeZone["UTC"]
    time.in_time_zone(zone).strftime(format)
  end

  def utc_time(time, format: "%b %-d, %Y %H:%M UTC")
    return "—" if time.blank?

    time.utc.strftime(format)
  end

  def percentage(value)
    "#{value.round(1)}%"
  end
end

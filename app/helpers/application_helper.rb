# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ActionView::Helpers::ActiveRecordHelper
  
  alias_method :original_error_messages_for, :error_messages_for 
  def error_messages_for(*params)
    picture_div = "<div id='error-messages-pic'></div>"
    original = original_error_messages_for(*params)
    clear_fix = "<div style='clear: both;'></div>"
    
    return original.blank? ? '' : picture_div + original + clear_fix 
  end

  # TODO: comment this, whats the difference between this and formal_link_to?
  def functional_link_to(*args, &block)
    if block_given?
      options = args.first
      html_options = args.second
      concat(functional_link_to(capture(&block), options, html_options))
    else
      name = args.first
      options = args.second || {}
      html_options = args.third

      url = url_for(options)
      
      html = "<form class=\"functional-form\">"
      html += "<input type=\"hidden\" value=\"#{url}\" name=\"url\" />" 
      html += link_to(name, "#", html_options)
      html += "</form>"
      
      return html
    end
  end

  # render link inside the form, handles :method and :confirm options
  def formal_link_to(*args, &block)
    options = html_options = name = nil
    if block_given?
      options = args.first
      html_options = args.second
      name = capture(&block)
    else
      name         = args.first
      options      = args.second || {}
      html_options = args.third
    end

    method = html_options.delete(:method) || "POST"
    method = method.to_s.upcase
    confirm = html_options.delete(:confirm)
    url = url_for(options)

    html = "<form class=\"formal-link\" action=\"#{url}\" method=\"post\">"
    html += "<input type=\"hidden\" value=\"#{confirm}\" name=\"confirm\" />" if confirm
    html += "<input type=\"hidden\" value=\"#{form_authenticity_token}\" name=\"authenticity_token\" />" 
    html += "<input type=\"hidden\" value=\"#{method}\" name=\"_method\" />" 
    html += link_to(name, "#", html_options)
    html += "</form>"
    
    if block_given?
      concat(html)
    else
      return html
    end
  end

  def title(title)
    title_parts = []
    if Project.current
      current_project = Project.current
      name = current_project.presentation_name
      title_parts << h(name) 
    end
    title_parts << h(title) unless title.nil? or title == ''
    title_parts << 'Banana Scrum'
    return title_parts.join(' - ')
  end

  def title_heading(title)
    return '' if title.nil?
    truncated_title = truncate(title)
    attributes = ''
    if truncated_title.length < title.length
      attributes = ' title="' + h(title) + '"'
    end
    return "<h1#{attributes}>#{h(truncated_title)}</h1>"
  end

  def new_login_info_content
    if User.current
      html = '<span>'
      if User.current.admin?
        html += link_to("Admin", admin_panel_url, :id => "admin")
      end
      html += '</span>'
      html += '<span>'
      html += link_to_unless(User.current.nil?, h(User.current.full_name), edit_profile_url, {:title => "View profile"})
      html += '</span>'
      html += '<span>'
      html += link_to( "Logout", logout_url)
      html += '</span>'
      return html
    end
  end

  def login_info_content
    if User.current
      html = '<div>'
      html += '<span>'
      html += link_to( image_tag('icons/logout.gif', :id => "logout-icon", :height => 16, :width => 16), logout_url)
      html += image_tag 'icons/user.gif', :id => "person-icon", :height => 16, :width => 16
      html += "Logged as: " + (link_to(h(User.current.full_name), edit_profile_url, {:title => "View profile"}) unless User.current.nil?)
      html += '</span>'
      html += '<span id="select-project">'
      html += 'Project: '
      
      html += select_tag(:project_id, projects_for_select)
      
      html += '</span>'
      if User.current && User.current.admin?
        html += link_to("Admin", admin_panel_url, :id => "admin")
      end
      
      html += '</div>'
      return html
    end
  end

  def old_layout_only(&block)
    unless User.current.try(:new_layout)
      concat(capture(&block))
    end
  end
  
  def new_layout_only(&block)
    if User.current.try(:new_layout)
      concat(capture(&block))
    end
  end


  # Puts pixels in the corners of containing div, note that it has to have positon:relative in it's style.
  def round_box(color="white", &block)
    pixel_divs = render(:partial => "shared/white_pixel_corners", :locals => {:color => color})
    if block_given? 
      data = capture(&block)
      concat(pixel_divs + data)
    else
      pixel_divs
    end
  end
  
  def round_tab(&block)
    resp = "<div class='round-tab-left'></div>"
    resp += capture(&block)
    resp += "<div class='round-tab-right'></div>"
    concat(resp)
  end
  

  def project_select
    if User.current
      select_tag(:project_id, projects_for_select)
    end
  end
  
  def projects_for_select

    collect_projects = lambda do |collection|
      collection.collect {|p| [p.presentation_name, url_per_role(p)]}.
        sort {|a, b| a[0].downcase <=> b[0].downcase }
    end
    
    projects = Project.find_all_for(User.current)
    current_project_url = url_per_role(@current_project)

    if projects.empty?
      projects_for_select = options_for_select([['No projects available', nil]])
    elsif projects.any? { |p| p.archived? }
      active_projects = collect_projects.call(projects.select{|p| !p.archived?})
      archived_projects = collect_projects.call(projects.select{|p| p.archived?})

      active_options = options_for_select(active_projects, current_project_url)
      archived_options = options_for_select(archived_projects, current_project_url)

      # merging with adding optgroup tags
      projects_for_select = options_for_select([['Choose...', nil]]) +
        optgroup_tag('Active Projects:', active_options.to_s) +
        optgroup_tag('Archived Projects:', archived_options.to_s )
    else
      projects_collection = collect_projects.call(projects)
      projects_for_select = options_for_select([['Choose...', nil]] + projects_collection, current_project_url)
    end

    return projects_for_select
  end

  def banana_version
    "Banana Scrum version #{BananaScrum::Version::STRING}"
  end

  def generate_menu(project)
    user = User.current
    menu_items = []

    if user.nil? && Domain.current
      menu_items.push({:name => "Login", :url => login_url})
    elsif project
      if project.domain.plan.timeline_view && User.current.new_layout
        menu_items.push(:name => "Timeline", :url => project_timeline_url(project))
      end
      menu_items.push(:name => "Backlog", :url => project_items_url(project))
      menu_items.push(:name => "Sprints List", :url => project_sprints_url(project))
      if project.last_sprint or @sprint
        menu_items.push(:name => "Sprint", :url => project_sprint_url(project, @sprint || project.last_sprint))
      end
    end
    return if menu_items.blank?
    html = '<ul id="top-menu">'
    menu_items.each do |item|
      camelized = item[:name].downcase.gsub(" ", "-")
      url = item[:url]
      if (@current_menu_item.try(:downcase) == item[:name].downcase) then
        html += "<li class='current #{item[:additional_class]}'><a href='#{url}'><div class='#{camelized}'>#{item[:name]}</div></a><div class='tab-underscore'></div>";
      else
        html += "<li class='not-current #{item[:additional_class]}'><a href='#{url}'><div class='#{camelized}'>#{item[:name]}</div></a>";
      end
    html += '</li>'
    end
    html += '</ul>'
  end

  def development_info
    unless ENV['RAILS_ENV'] == 'production'
      "||DEVELOPMENT||"
    end
  end

  def domain_name
    if Domain.current
      Domain.current.full_name || Domain.current.name
    end
  end

  def setting(name)
    Preference.get_setting(name)
  end

  def nl2br(s)
    s.gsub(/(\r\n)/, "<br />").gsub(/(\r|\n)/, "<br />")
  end
 
  def debtor_warning
    return '' unless(Domain.current && Domain.current.debtor?)
    layout_path = "/warnings/warning_box"
    case Domain.current.warning
      when Domain::DEBTOR_WARNINGS[:first_warning]
        render(:partial => "warnings/first_warning", :layout => layout_path)
      when Domain::DEBTOR_WARNINGS[:second_warning]
        render(:partial => "/warnings/second_warning", :layout => layout_path)
      when Domain::DEBTOR_WARNINGS[:domain_blocked]
        render(:partial => "/warnings/domain_blocked", :layout => layout_path)
      else
        ''
    end
  end

  def generate_notice
    user = User.current
    return if user.nil?

    latest_news = Domain.current && News.latest_for_plan(Domain.current.plan)
    if latest_news
      if user.last_news_read_date.nil? or user.last_news_read_date < latest_news.created_at
        return generate_notice_tag(user, latest_news)
      end
    end
  end

  def generate_notice_tag(user, news)
    content_tag(:div, :class => "news-reminder") do
      dismiss = functional_link_to("Dismiss", dismiss_unread_news_url, :class => "dismiss-link")
      content_tag(:span, news.text, :class => 'news-content') + content_tag(:div, dismiss, :class => 'link') + round_box
    end
  end

  def hide_form_link(text = 'Cancel')
    "<a href='#' class='hide-form'>#{text}</a>"
  end

  def submit_button(text, options = {})
    options = {:class => 'button'}.merge(options)
    submit_tag(text, options)
  end
  
  def timeline_section(options = {}, &block) 
    expand_links = %Q~
      <span class="expand-links">
        <a href="#" class="expand-list">Expand all</a> /
        <a href="#" class="collapse-list">Collapse all</a>
      </span>
    ~ 
    velocity_widget = render(:partial => "items/long_term_view") if options[:velocity_widget]
    html = %Q~
      <div class="expandable #{options[:expanded] ? 'expanded' : 'collapsed'} #{options[:header_class]} timeline #{'expandable-list' if options[:expand_links]}">
        #{round_box}
        <div class="timeline-header">
          <a href="#" class="expandable-link">#{expandable_image_tag(:expanded => options[:expanded])}</a>
          <span class="timeline-header-title">#{options[:title]}</span>
          #{expand_links if options[:expand_links]}
          #{velocity_widget if options[:velocity_widget]} 
          <div style="clear: both"> </div>
        </div>
  
        <div class="toggable-visibility #{options[:content_class]}">
          #{round_box("#b0bbbd")}
          #{capture(&block)}
        </div>
      </div>
    ~
    concat(html)
  end
  
  def key_form_field(form, *args)
    options = args.extract_options!
    options.reverse_merge!({:label => true})

    %Q~
      <fieldset class="key-field-form">
        #{options[:label] ? '<label for="key">Validation key</label><br />': ''}
        #{form.nil? ? text_field_tag(:key) : form.text_field(:key, :name => "key")}
      </fieldset>
    ~
  end

  private
  
  def optgroup_tag(label,content)
    content_tag(:optgroup, content, :label=> label)
  end
  
  def url_per_role(project)
    return nil unless project

    if params[:controller] == 'backlog' then
      return project_items_url(project)
    elsif params[:controller] == 'sprints' then
      if params[:action] == 'show' and project.last_sprint
        return project_sprint_url(project, project.last_sprint)
      end
      return project_sprints_url(project)
    end
    
    roles = project.get_user_roles(User.current)
    if roles.any? {|role| role.name == "Product Owner"}
      return project_items_url(project)
    else
      return project_sprints_url(project)
    end
  end

  def burnchart_path
    "#{ActionController::Base.relative_url_root}/#{ActionController::Base.asset_host}open-flash-chart.swf"
  end
end

module ActionView
  module Helpers
    class FormBuilder
      def calendar_date_select(method, options = {})
        @template.calendar_date_select(@object_name, method, options.merge(:object => @object))
      end
    end
  end
end

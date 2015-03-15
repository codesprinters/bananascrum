module BacklogHelper

  def drop_arrow(item)
    return unless item
    old_layout_only do
      return image_tag('icons/go-down.gif', :height => 16, :width => 16, :class => 'icon drop-arrow')
    end
    new_layout_only do
      return image_tag('mud/go_down.png', :height => 16, :width => 21, :class => 'icon drop-arrow')
    end
  end

  def assign_arrow(item)
    return unless item
    old_layout_only do
      return image_tag('icons/go-up.gif', :height => 16, :width => 16, :class => 'icon assign-arrow')
    end
    new_layout_only do
      return image_tag('mud/go_up.png', :height => 16, :width => 21, :class => 'icon assign-arrow')
    end
  end

  def task_li_hash(task)
    klass = "task "
    klass += cycle "odd", "even", :name => "task"
    klass += " done" if task.is_done
    id = "task-#{task.id}"
    return { :class => klass, :id => id }
  end

  def backlog_item_class(item)
    return unless (item || item.item?)
    klass = "backlog-item backlog-element item"
    if item.estimate.nil?
      klass += " unestimated-backlog-item"
    elsif item.estimate == Item::INFINITY_ESTIMATE_REPRESENTATIVE
      klass += " infinity-estimate-backlog-item"
    end
    klass += " item-done" if item.is_done
    klass
  end

  def long_or_multiline?(text)
    return false if text.nil? || (!text.kind_of? String)
    return true if text.split(/\n/).length > 2 || text.length > 80
    false
  end

  def expandable_image_tag(opts = {})
    klass = opts[:expanded] ? "collapse" : "expand"
    html = %Q~
      <div class="icon expand-icon #{klass}"> </div>
    ~
  end

  def tag_list_select
    html = "<div class='checkbox-dropdown'>"
    Project.current.tags.each_with_index do |tag, index|
      html += label_tag "tags[#{index}]", check_box_tag("tags[#{index}]", tag.id, false, :class => 'checkbox-dropdown-input') + h(tag.name)
    end
    html += "</div>"
    return html
  end

  def new_object_menu_links(item, new_layout = true)
    html = ""
    html += '<ul id="submenu_'+item.id.to_s+'" class="submenu-links">'
    html += content_tag :li, new_task_link(item, new_layout)
    html += content_tag :li, attach_file_link(item, new_layout)
    html += content_tag :li, comment_link(item), :class => (item.comments.blank? ? "" : "always-visible"), :title => 'Add a comment'
    unless new_layout
      html += content_tag :li, copy_item_link(item, new_layout)
    end
    html += "</ul>"   
  end

  def item_logs(item)
    html = ""
    html += "<span class='item-log'>"
    unless item.creator.blank?
      html += "Created by #{h item.creator.login}"
    end

    unless item.update?
      html += " [#{h item.created_on.strftime("%H:%M #{User.current.prefered_date_format}")}]"
    end

    if item.last_updated_by
      html += " &mdash; Last modified by #{h item.last_updated_by.login}"
      html += " [on #{h item.logs.of_update.last.created_at.strftime("%H:%M #{User.current.prefered_date_format}")}]"
    end
    html += "</span>"
  end

  def attach_file_link(item, new_layout = true)
    title = new_layout ? '&nbsp;' : 'Attach a file' 
    return functional_link_to(title, new_project_attachment_url(Project.current, :item_id => item.id), :class => 'attach-file-link', :title => "Attach a file")
  end

  def copy_item_link(item, new_layout = true)
    title = new_layout ? '&nbsp;' : 'Copy item' 
    return functional_link_to(title, copy_project_item_url(@current_project, :id => item.id), :class => "copy-item-link", :title => 'Copy this item')
  end

  def new_task_link(item, new_layout = true)
    unless item.project.user_has_this_role_only?(User.current, "product_owner")
      title = new_layout ? '&nbsp;' : 'Add task' 
      return functional_link_to title, new_project_task_url(@current_project, :item_id => item.id), :class => 'new-task-link', :title => 'Add a new task'
    end
  end

  def attachment_list(item)
    html = '<ul class="attachment-list">'
    html += render(:partial => 'attachments/file.html.erb', :collection => item.clips) unless item.clips.blank?
    html += '</ul>'
    return html
  end

  # displays names of attachments only, used for printing
  def attachment_names_list(item)
    list = ''
    text = '<span class="attachments-title">Attachments:</span>'
    any_attachment = false
    list += '<ul class="attachment-list">'
    item.clips.each do |clip|
      unless clip.blank?
        any_attachment = true
        list += "<li>#{clip.content_file_name}</li>"
      end
    end

    list += '</ul>'
    return (any_attachment ? text : '')+ list
  end


  # Function which gets array as parametr [1,2], converts it to
  # hash [1=>1, 2=>2], and modifies hash keys using code block if given
  def select_choices_readable(choices)
    hash = Hash.new
    if block_given?
      choices.each { |c| hash[c] = yield(c) }
    else
      choices.each { |c| hash[c] = "#{c}" }
    end
    return hash
  end

  def select_item_estimate_choices(skip_infinity = false)
    for_in_place_editor = false
    sort_index =  for_in_place_editor ? 0 : 1
    est = Item.estimate_choices
    if skip_infinity then
      est = est.reject {|x,y| x == BacklogItem::INFINITY_ESTIMATE_REPRESENTATIVE}
    end
    hash = select_choices_readable(est) do |i|
      Item.readable_estimate(i)
    end
    # sorting elements for select - by select value. Support for max one nil value in select
    hash = hash.invert

    hash.sort {|a, b| if a[sort_index].nil? then -1 elsif b[sort_index].nil? then 1 else a[sort_index] <=> b[sort_index] end}
  end
  
  def comment_link(item)
    if item.comments.size > 0
      title = 'Comments'
    else
      title = 'Add comment'
    end
    title << ' '
    title << "<span class='item-log'>"
    if item.comments.size > 0
      title << "[#{item.comments.size}]"
    end
    title << "</span>"
    
    functional_link_to(title, new_project_item_comment_path(Project.current, item), {:class => 'show-comments-link'})
  end

  def leave_open_checkbox
    html = "<label class = 'leave-open-box'>"
    html += check_box_tag 'leave-open', 1, params[:'leave-open'], :class => 'leave-open'
    html += "Leave this form open</label>"
    return html
  end
  
  def single_item_box(title, &block)
    content = capture(&block)
    html = %Q~
      <div class="expandable expanded single-item-box">
        <div class="single-item-header">
          <a href="#" class="expandable-link">
            #{expandable_image_tag(:expanded => true)}
          </a>
          <span class="single-item-header-title">#{title}</span>
        </div>
        <div class="toggable-visibility">
          #{content}
        </div>  
      </div>
    ~
    concat(html)
  end
end

module SprintsHelper
  #FIXME: damn ugly, move to partial
  def sprint_information(sprint)
    resp = []
    if (sprint.from_date..sprint.to_date).include?(Date.current)
      resp << "<span class='verbose-information'>Current sprint, ending on #{h @sprint.to_date.strftime(User.current.prefered_date_format)}"
      if @sprint.to_date == Date.current then 
        resp << "(today).</span>"
        resp << '<div class="legend today">'
        resp << '<div class="remaining-workdays smallsize">This sprint is ending</div>'
        resp << 'today'
        resp << '</div>'
      else 
        resp << "(in #{h @sprint.remaining_days.to_i} days).</span>"
        resp << '<div class="legend">'
        resp << '<div class="smallsize">This sprint is ending in</div>'
        resp << "#{h(@sprint.remaining_days.to_i)} Days"
        resp << "<div class=\"remaining-workdays smallsize\">#{@sprint.remaining_work_days} work days remaining</div>"
        resp << "</div>"
      end 
    elsif @sprint.ended?
      resp << "<span class='verbose-information'>Past sprint, ended on #{h @sprint.to_date.strftime(User.current.prefered_date_format)} (#{@sprint.length} days long).</span>"
      resp << '<div class="legend">'
      resp << 'Sprint already ended'
      resp << '</div>'
    else 
      resp << "<span class='verbose-information'>Future sprint, starts on #{h @sprint.from_date.strftime(User.current.prefered_date_format)} (#{h @sprint.length} days long).</span>"
      resp << '<div class="legend">'
      resp << 'Sprint not started yet'
      resp << '</div>'
    end 
    resp.join("\n")
  end
end

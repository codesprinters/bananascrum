module NegativeCaptchaViewHelpers
  def negative_captcha(captcha)
    [
      hidden_field_tag('timestamp', captcha.timestamp.to_i), 
      hidden_field_tag('spinner', captcha.spinner),
    ].join
  end
  
  def negative_text_field_tag(negative_captcha, field, options={})
    text = [
      text_field_tag(negative_captcha.fields[field], negative_captcha.values[field], negative_html_options(options)),
      negative_captcha_hidden { text_field_tag(field, '', :tabindex => '999', :autocomplete => 'off') }
    ].join
    mark_error(negative_captcha, field, text)
  end
  
  def negative_text_area_tag(negative_captcha, field, options={})
    text = [
      text_area_tag(negative_captcha.fields[field], negative_captcha.values[field] || options[:value], negative_html_options(options)),
      negative_captcha_hidden { text_area_tag(field, '', :tabindex => '999', :autocomplete => 'off') }
    ].join
    mark_error(negative_captcha, field, text)
  end

  def negative_password_field_tag(negative_captcha, field, options={})
    text = [
      password_field_tag(negative_captcha.fields[field], negative_captcha.values[field] || options[:value], negative_html_options(options)),
      negative_captcha_hidden { password_field_tag(field, '', :tabindex => '999', :autocomplete => 'off') }
    ].join
    mark_error(negative_captcha, field, text)
  end

  def negative_check_box_tag(negative_captcha, field, options={})
    checked = !(negative_captcha.values[field] || options[:value]).nil?
    text = [
      check_box_tag(negative_captcha.fields[field], negative_captcha.values[field] || options[:value] || '1', checked, negative_html_options(options)),
      negative_captcha_hidden { check_box_tag(field, negative_captcha.values[field] || options[:value] || '1', false, :tabindex => '999', :autocomplete => 'off') }
    ].join
    mark_error(negative_captcha, field, text)
  end
  
  #TODO: Select, check_box, etc
  private
  def mark_error(negative_captcha, field, text)
    if negative_captcha.object && negative_captcha.object.errors.on(field)
      field_error_proc.call(text)
    else
      text
    end
  end

  def negative_captcha_hidden
    "<div style='position: absolute; left: -2000px;'>" + yield + "</div>"
  end

  def negative_html_options(options)
    { :tabindex => '1' }.merge(options)
  end
end

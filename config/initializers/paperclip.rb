Paperclip.interpolates :attachments_path do |attachment, style|
  AppConfig.attachments_path.gsub(':rails_root', RAILS_ROOT)
end

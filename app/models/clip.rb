class Clip < ActiveRecord::Base
  include DomainChecks # security checks
  include PlanLimits
  
  checks_plan_using AttachmentsLimitChecker

  belongs_to :item
  validates_presence_of :item_id

  if AppConfig.use_aws_s3
    has_attached_file :content, {
      :storage => :s3,
      :s3_credentials => "#{RAILS_ROOT}/config/amazon_s3.yml",
      :s3_permissions => :private,
      :s3_headers => { "Content-Disposition" => 'attachment' },
      :url => :s3_path_url,
      :path => "attachments/:id/:basename.:extension"
    }
  else
    has_attached_file :content, {
      :storage => :filesystem,      
      :path => ":attachments_path/:id/:basename.:extension"
    }
  end

  validates_attachment_presence :content
  validates_attachment_size :content, { :in => 1..5.megabytes }
  validates_uniqueness_of :content_file_name, :scope => [:item_id]

  def temporary_link
    bucket = content.s3_bucket.to_s
    content.s3.interface.get_link(bucket, content.path, 30.minutes)
  end
  
  def size_with_units
    units = %w{B KB MB}
    step = 1024
    
    size = self.content_file_size.to_f
    units.each do |unit|
      return size.to_i.to_s + unit if size < step
      size /= step
    end
  end

  def file_path
    config_clip_path = AppConfig.attachments_path.gsub(':rails_root', RAILS_ROOT)
    return File.join(config_clip_path, self.id.to_s, self.content_file_name)
  end
end

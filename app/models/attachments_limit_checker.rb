class AttachmentsLimitChecker < LimitChecker
  def plan_limit
    @plan.bytes_limit
  end

  def instance_using(clip)
    clip.content_file_size
  end

  def domain_using(skipped_instance = nil)
    where = "domain_id = :domain_id"
    if skipped_instance && !skipped_instance.new_record?
      conditions = [where + " AND id != :id", {:domain_id => @domain.id, :id => skipped_instance.id}]
    else
      conditions = [where, {:domain_id => @domain.id}]
    end
    Clip.sum(:content_file_size, :conditions => conditions)
  end

  def error_message
    "Plan limit exceeded: attachmets volume to big. " +
      "Consider upgrading plan or deleting some attachments."
  end
end

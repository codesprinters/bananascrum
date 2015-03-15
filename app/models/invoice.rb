class Invoice < ActiveRecord::Base
  belongs_to :payment
  belongs_to :domain
  has_one :customer, :through => :payment
  
  validates_presence_of :payment, :transaction_id
  validates_uniqueness_of :invoice_number
  validates_inclusion_of :invoice_type, :in => %w( vat trade )

  before_validation_on_create :set_issue_date
  before_validation_on_create :set_domain
  before_validation_on_create :set_invoice_type
  before_validation_on_create :set_invoice_number
  
  named_scope :without_pdfs, :conditions => ["original_filename IS NULL OR copy_filename IS NULL"]
  
  def generate_pdfs(eur_rate, force = false)
    if self.has_pdf_files?
      unless force
        raise "PDFs for the invoice #{self.inspect} have already been generated!"
      end
    end
    self.delete_pdfs
    self.original_filename = InvoiceGenerator.new(self, { :copy => false, :eurpln => eur_rate.rate, :rate_date => eur_rate.publish_date }).generate
    self.copy_filename = InvoiceGenerator.new(self, { :copy => true, :eurpln => eur_rate.rate, :rate_date => eur_rate.publish_date}).generate
    save!
  end
  
  def delete_pdfs
    [self.original_filename, self.copy_filename].each do |file|
      File.delete(file) if file && File.exist?(file)
    end
  end
  
  def has_pdf_files?
    return self.original_filename && File.exist?(self.original_filename) && self.copy_filename && File.exist?(self.copy_filename)
  end
  
  private
  def set_invoice_type
   self.invoice_type ||= self.domain.customer.pays_with_vat? ? 'vat' : 'trade'
  end

  def set_domain
    self.domain = self.payment.domain
  end

  def set_invoice_number
    return if invoice_number
    year = issue_date.year
    month = sprintf("%02d", issue_date.month)
    number = InvoiceNumberSequencer.next_number_for(year, month, invoice_type)
    self.invoice_number = "BS/#{number}/#{month}/#{year}/#{invoice_type_short}"
  end

  def invoice_type_short
    return 'K' if invoice_type == 'trade'
    return 'P' if invoice_type == 'vat'
  end
  
  def set_issue_date
    self.issue_date ||= Date.today
  end

end

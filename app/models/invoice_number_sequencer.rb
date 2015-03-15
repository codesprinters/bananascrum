class InvoiceNumberSequencer < ActiveRecord::Base
  validates_presence_of :number, :month, :year, :invoice_type
  validates_inclusion_of :invoice_type, :in => %w( vat trade )
  
  def self.next_number_for(year, month, invoice_type)
    sequencer = self.find_or_create_by_year_and_month_and_invoice_type(year, month, invoice_type)
    sequencer.increment!(:number)
    sequencer.number
  end

end

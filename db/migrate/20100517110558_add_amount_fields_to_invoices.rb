class AddAmountFieldsToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :netto_eur, :decimal, :precision => 15, :scale => 2
    add_column :invoices, :brutto_eur, :decimal, :precision => 15, :scale => 2
    
    execute("UPDATE invoices JOIN payments ON payments.id = invoices.payment_id SET netto_eur = payments.amount, brutto_eur = payments.amount WHERE invoices.invoice_type = 'trade'")
    execute("UPDATE invoices JOIN payments ON payments.id = invoices.payment_id SET netto_eur = payments.amount / 1.22, brutto_eur = payments.amount WHERE invoices.invoice_type = 'vat'")
    
    change_column :invoices, :netto_eur, :decimal, :precision => 15, :scale => 2, :null => false
    change_column :invoices, :brutto_eur, :decimal, :precision => 15, :scale => 2, :null => false
  end

  def self.down
    remove_column :invoices, :netto_eur
    remove_column :invoices, :brutto_eur
  end
end
 
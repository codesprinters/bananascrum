class Admin::InvoicesController < AdminBaseController

  def show
    invoice = Domain.current.invoices.find(params[:id])
    if !File.exist?(invoice.original_filename)
      return render_404 
    end
    send_file invoice.original_filename, :type => "application/pdf"
  end
end
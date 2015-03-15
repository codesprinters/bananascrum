class CustomEvent
  include_class "com.itextpdf.text.pdf.PdfPCell"
  include_class "com.itextpdf.text.pdf.PdfPTable"
  include_class "com.itextpdf.text.Image"
  include_class "com.itextpdf.text.Paragraph"
  include_class "com.itextpdf.text.pdf.PdfPCellEvent"
  include_class "com.itextpdf.text.pdf.events.PdfPCellEventForwarder"
  include com.itextpdf.text.pdf.PdfPCellEvent
  
  def initialize(image)
    @image = image
  end

  def cellLayout(cell,rect,canvas)
    cb = canvas[PdfPTable::BACKGROUNDCANVAS]
    @image.scaleToFit(rect.getWidth() - 4, rect.getHeight())
    @image.setAbsolutePosition(rect.getLeft(), rect.getBottom())
    cb.addImage(@image)
  end
end

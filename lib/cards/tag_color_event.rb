class TagColorEvent

  include_class "com.itextpdf.text.pdf.PdfPCell"
  include_class "com.itextpdf.text.pdf.PdfPTable"
  include_class "com.itextpdf.text.Image"
  include_class "com.itextpdf.text.Paragraph"
  include_class "com.itextpdf.text.pdf.PdfPCellEvent"
  include_class "com.itextpdf.text.pdf.events.PdfPCellEventForwarder"
  include_class "com.itextpdf.text.BaseColor"

  include com.itextpdf.text.pdf.PdfPCellEvent

  def initialize(tag)
    red,green,blue = TagColors::getBackground(tag.color_no)
    @background_color = BaseColor.new(red,green,blue)
  end

  def cellLayout(cell,rect,canvas)
    cb = canvas[PdfPTable::LINECANVAS]
    cb.roundRectangle(rect.getLeft() + 1.5, rect.getBottom() + 1.5, rect.getWidth() - 3, rect.getHeight() - 3, 4)
    cb.setColorFill(@background_color)
    cb.fill()
  end
end

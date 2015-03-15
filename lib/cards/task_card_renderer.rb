class TaskCardRenderer
  
  require 'java'
  include_class "com.itextpdf.text.BaseColor"
  include_class "com.itextpdf.text.Image"
  include_class "com.itextpdf.text.pdf.BaseFont"
  include_class "com.itextpdf.text.pdf.PdfPTable"
  include_class "com.itextpdf.text.pdf.PdfPCell"
  include_class "com.itextpdf.text.pdf.PdfPCellEvent"
  include_class "com.itextpdf.text.pdf.events.PdfPCellEventForwarder"
  include_class "com.itextpdf.text.Font"
  include_class "com.itextpdf.text.Chunk"
  include_class "com.itextpdf.text.Paragraph"

  CARDS_PATH = File.dirname(File.expand_path(__FILE__)) 

  def initialize
    @font = BaseFont.createFont("#{CARDS_PATH}/LiberationSans-Regular.ttf", BaseFont::IDENTITY_H, BaseFont::EMBEDDED)
    @item_bg = Image.getInstance("#{CARDS_PATH}/index_card_300_task.jpg")
    @events = PdfPCellEventForwarder.new
    @events.addCellEvent(CustomEvent.new(@item_bg))
  end

  def render_card(element, cell)

    cell.setCellEvent(@events)

    inner_table = prepare_inner_table(element)

    # estimate
    estimate_cell = render_estimate(element)
    inner_table.addCell(estimate_cell)

    # summary
    summary_cell = render_summary(element)
    inner_table.addCell(summary_cell)

    # users
    users_cell = render_users(element.users)
    inner_table.addCell(users_cell)

    # item name
    item_name_cell = render_parent_name(element)
    inner_table.addCell(item_name_cell)

    cell.addElement(inner_table)
    return cell
  end

  protected
  def render_users_caption(users_number, font)
    caption = case
    when users_number == 0
      "No users assigned"
    when users_number == 1
      "Assigned user: "
    else
      "Assigned users: "
    end

    chunk = Chunk.new(caption, font)
    return chunk
  end

  def render_parent_name(element)
    font = Font.new(@font, 10)
    font.setColor(BaseColor::DARK_GRAY)
    parent_caption = "Belongs to: #{element.item.user_story}"
    item_name_paragraph = Paragraph.new(parent_caption, font)
    item_name_paragraph.setAlignment('LEFT')

    cell = PdfPCell.new(item_name_paragraph)
    cell.setVerticalAlignment(PdfPCell::ALIGN_LEFT)
    cell.border = PdfPCell::NO_BORDER
    cell.setPaddingTop(10)
    
    return cell
  end

  def render_summary(element)
    font = Font.new(@font, 12)
    font.setColor(BaseColor::DARK_GRAY)
    font.setStyle('bold')
    summary_caption = "#{element.summary}"
    summary_paragraph = Paragraph.new(summary_caption, font)
    summary_paragraph.setAlignment('LEFT')

    cell = PdfPCell.new(summary_paragraph)
    cell.setVerticalAlignment(PdfPCell::ALIGN_LEFT)
    cell.border = PdfPCell::NO_BORDER
    cell.setPaddingBottom(15)
    
    return cell
  end

  def render_users(users)
    font = Font.new(@font, 12)
    font.setColor(BaseColor::DARK_GRAY)

    caption_chunk = render_users_caption(users.size, font)
    login_string = users.map {|u| u.login}.join(", ")
    login_chunk = Chunk.new(login_string, font)

    users_paragraph = Paragraph.new()
    users_paragraph.setAlignment('LEFT')
    users_paragraph.add(caption_chunk)
    users_paragraph.add(login_chunk)

    cell = PdfPCell.new(users_paragraph)
    cell.setVerticalAlignment(PdfPCell::ALIGN_LEFT)
    cell.border = PdfPCell::NO_BORDER
    
    return cell
  end

  def render_estimate(element)
    unit = element.item.project.task_unit
    font = Font.new(@font, 20)
    font.setColor(BaseColor::DARK_GRAY)

    estimate_string = "#{element.estimate} #{unit}"
    paragraph = Paragraph.new(estimate_string, font)
    paragraph.setAlignment('RIGHT')

    cell = PdfPCell.new()
    cell.border = PdfPCell::NO_BORDER
    cell.addElement(paragraph)
    cell.setHorizontalAlignment(PdfPCell::ALIGN_RIGHT)
    return cell
  end
  
  def prepare_inner_table(element)
    inner_table = PdfPTable.new(1)
    inner_table.getDefaultCell().setBorder(PdfPCell::NO_BORDER)
    inner_table.setWidthPercentage(100)
    return inner_table
  end
end

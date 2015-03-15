class ItemCardRenderer

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
    @item_bg = Image.getInstance("#{CARDS_PATH}/index_card_300.jpg")
    @events = PdfPCellEventForwarder.new
    @events.addCellEvent(CustomEvent.new(@item_bg))
  end

  def render_card(element, cell)

    cell.setCellEvent(@events)

    inner_table = prepare_inner_table(element)
    colspan = inner_table.getNumberOfColumns
    
    # estimate
    estimate_cell = render_estimate(element, colspan)
    inner_table.addCell(estimate_cell)

    # tags
    element.tags.each_slice(3) do |tag_slice|
      tag_slice.each do |tag|
        tag_cell = render_tag(tag)
        inner_table.addCell(tag_cell)
      end
      if tag_slice.size < 3
        inner_table.completeRow()
      end
    end

    # user story
    user_story = render_user_story(element)
    user_story_cell = PdfPCell.new(user_story)
    user_story_cell.border = PdfPCell::NO_BORDER
    user_story_cell.setColspan(colspan) if colspan > 0
    user_story_cell.setHorizontalAlignment(PdfPCell::ALIGN_MIDDLE)
    inner_table.addCell(user_story_cell)

    cell.addElement(inner_table)
    return cell
  end

  protected
  def prepare_inner_table(element)
    tag_count = element.tags.size
    colspan = tag_count < 3 ? tag_count : 3
    columns = colspan > 0 ? colspan : 1
    inner_table = PdfPTable.new(columns)
    inner_table.getDefaultCell().setBorder(PdfPCell::NO_BORDER)
    inner_table.setWidthPercentage(100)
    return inner_table
  end

  def render_user_story(element)
    font = Font.new(@font, 20)
    font.setColor(BaseColor::DARK_GRAY)
    paragraph = Paragraph.new(element.user_story, font) 
  end

  def render_estimate(element, colspan)
    estimate = estimate_representation(element.estimate)
    font = Font.new(@font, 20)
    estimate_font = Font.new(@font, 20)

    if ["?","∞"].include?(estimate)
      estimate_font.setColor(BaseColor.new(208,70,38))
    else
      estimate_font.setColor(BaseColor::DARK_GRAY)
    end

    unit = element.project.backlog_unit
    estimate_chunk = Chunk.new("#{estimate} ", estimate_font)
    font.setColor(BaseColor::DARK_GRAY)
    unit_chunk = Chunk.new(unit, font)
    paragraph = Paragraph.new
    paragraph.setAlignment('RIGHT')
    paragraph.add(estimate_chunk)
    paragraph.add(unit_chunk)

    cell = PdfPCell.new()
    cell.border = PdfPCell::NO_BORDER
    cell.addElement(paragraph)
    cell.setColspan(colspan) if colspan > 0
    cell.setHorizontalAlignment(PdfPCell::ALIGN_RIGHT)
    return cell
  end

  def render_tag(tag)
    red, green, blue= TagColors::getForeground(tag.color_no)
    foreground_color = BaseColor.new(red, green, blue)
    font = Font.new(@font, 7)
    font.setStyle('bold')
    font.setColor(foreground_color)

    tag_name = Paragraph.new(tag.name, font)
    tag_name.setAlignment(3)

    cell = PdfPCell.new(tag_name)
    cell.setVerticalAlignment(PdfPCell::ALIGN_RIGHT)
    cell.border = PdfPCell::NO_BORDER
    cell.setCellEvent(TagColorEvent.new(tag))
    cell.setPaddingLeft(10)
    cell.setPaddingBottom(5)

    return cell
  end

  def estimate_representation(estimate)
    case
    when estimate.nil?
      "?"
    when estimate == 9999
      "∞"
    else estimate
    end
  end
end

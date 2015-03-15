class CardGenerator
  require "java"

  CARDS_PATH = File.dirname(File.expand_path(__FILE__)) 
  ITEXT_PATH = File.join(RAILS_ROOT, 'vendor', 'itext', 'iText-5.0.2.jar')
  require ITEXT_PATH

  include_class "java.io.ByteArrayOutputStream"
  include_class "com.itextpdf.text.pdf.PdfWriter" 
  include_class "com.itextpdf.text.pdf.PdfPTable"
  include_class "com.itextpdf.text.Document" 
  include_class "com.itextpdf.text.Paragraph"
  include_class "com.itextpdf.text.Chunk"
  include_class "com.itextpdf.text.pdf.PdfPCell"
  include_class "com.itextpdf.text.Font"
  include_class "com.itextpdf.text.BaseColor"
  include_class "com.itextpdf.text.pdf.BaseFont"
  include_class "com.itextpdf.text.pdf.ColumnText"

  DEFAULTS = {:paper => 'a4', :orientation => 'portrait'}

  attr_reader :card_spacing, :background_image, :column_count, :row_count
  attr_accessor :options, :elements, :document, :events, :table
  
  def initialize(items = [], options = {})
    @elements = items
    @options = DEFAULTS.merge(options) 

    document_size = get_page_size
    @document = com.itextpdf.text.Document.new(document_size)
    @document.setMargins(10,5,10,10)
    @font = BaseFont.createFont("#{CARDS_PATH}/LiberationSans-Regular.ttf", BaseFont::IDENTITY_H, BaseFont::EMBEDDED)
    #@task_bg = Image.getInstance("#{CARDS_PATH}/index_card_300_task.jpg")

    @byte_array = java.io.ByteArrayOutputStream.new
    @writer = com.itextpdf.text.pdf.PdfWriter.getInstance(@document, @byte_array)
    @small_font = Font.new(@font, 8)

    @row_count = 3
    @column_count = 2
    @max_elements_on_page = @row_count * @column_count

    @current_sprint = Sprint.find(@options[:sprint_id]) unless @options[:sprint_id].nil?
    @current_project = Project.find_by_name(@options[:project_id]) unless @options[:project_id].nil?
    @generation_time = Date.today.to_s
  end

  def generate_output
    render_content do
      page_number = 0
      @elements.each_slice(@max_elements_on_page) do |slice|
        page_number += 1
        page = render_page(slice, page_number)
        @document.add(page)
        render_footer_info(page_number)
      end
    end
  end

  def render_page(elements, page_number)
    table = setup_grid
    elements.each_slice(@column_count) do |row|
      row.each do |element|
        renderer = get_renderer_for_element(element)
        base_cell = prepare_default_cell
        rendered_cell = renderer.render_card(element, base_cell)
        table.addCell(rendered_cell)
      end
      if row.size < @column_count
        table.completeRow()
      end
    end
    return table
  end

  def render_content
    @document.open
    yield if block_given?
    @document.close
    return String.from_java_bytes(@byte_array.toByteArray)
  end

  protected
  def get_renderer_for_element(element)
    case
    when element.class.to_s == 'Item'
      @item_renderer = ItemCardRenderer.new unless @item_renderer
      return @item_renderer
    when element.class.to_s == 'Task'
      @task_renderer = TaskCardRenderer.new unless @task_renderer
      return @task_renderer
    else
      raise "Unknown card element type to render: #{element.class.to_s}"
    end
  end

  def render_footer_info(page_number)
    pages_total = get_total_pages_count

    footer_string = case
                    when @options[:context] == 'backlog'
                      "Printed from Banana Scrum. Backlog item cards from product backlog of project \"#{@current_project.presentation_name}\" generated on #{@generation_time}. Page #{page_number} of #{pages_total}."
                    when @options[:contents] == 'items' && @options[:context] == 'sprint'
                      "Printed from Banana Scrum. Backlog item cards from sprint \"#{@current_sprint.name}\" of project \"#{@current_project.presentation_name}\" generated on #{@generation_time}. Page #{page_number} of #{pages_total}."
                    when @options[:contents] == 'all' && @options[:context] == 'sprint'
                      "Printed from Banana Scrum. Backlog item cards and task cards from sprint \"#{@current_sprint.name}\" of project \"#{@current_project.presentation_name}\" generated on #{@generation_time}. Page #{page_number} of #{pages_total}."
                    when @options[:contents] == 'tasks'
                      "Printed from Banana Scrum. Task cards from sprint \"#{@current_sprint.name}\" of project \"#{@current_project.presentation_name}\" generated on #{@generation_time}. Page #{page_number} of #{pages_total}."
                    else
                      "Printed from Banana Scrum on #{@generation_time}. Page #{page_number} of #{pages_total}."
                    end

    footer = PdfPTable.new(1)
    footer.setTotalWidth(500)
    cell = PdfPCell.new
    cell.border = PdfPCell::NO_BORDER
    cell.addElement(Paragraph.new(footer_string, @small_font))
    footer.addCell(cell)
    cb = @writer.getDirectContent()
    footer.writeSelectedRows(0, -1, ((@document.right() - @document.left()) / 2) - 250, 40, cb)
  end

  def get_total_pages_count
    element_count = @elements.size
    elements_on_page = @column_count * @row_count
    return (element_count.to_f / elements_on_page.to_f).ceil.to_i
  end

  def prepare_default_cell
    cell = PdfPCell.new
    cell.border = PdfPCell::NO_BORDER
    cell.setFixedHeight(210)
    cell.setPaddingBottom(20)
    cell.setPaddingLeft(20)
    cell.setPaddingRight(20)
    cell.setPaddingTop(40)
    
    return cell
  end

  def setup_grid
    grid = PdfPTable.new(@column_count)
    grid.getDefaultCell().setBorder(PdfPCell::NO_BORDER)
    grid.setWidthPercentage(100)
    return grid
  end

  def get_page_size
    # could be coded nicer however iText's Rectangle is immutable, so 
    # we can't rotate it after creation.

    if @options[:paper] == 'a4'
      if should_rotate?
        ps = com.itextpdf.text.PageSize::A4.rotate
      else
        ps = com.itextpdf.text.PageSize::A4
      end
    elsif @options[:paper] == 'letter'
      if should_rotate?
        ps = com.itextpdf.text.PageSize::LETTER.rotate
      else
        ps = com.itextpdf.text.PageSize::LETTER
      end
    end

    return ps
  end

  def should_rotate?
    @options[:orientation] == 'landscape'
  end
end

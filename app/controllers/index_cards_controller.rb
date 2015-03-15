class IndexCardsController < ProjectBaseController
  helper :application
  before_filter :xhr_only, :only => [:index]

  def index
    @context = params['context'] == 'sprint' ? 'sprint' : 'backlog'
    @sprint_id = params['sprint_id'] unless params['sprint_id'].nil?
    render_to_json_envelope({:layout => false})
  end

  def pdf
    begin

      @options = parse_options(params)
      @sprint = Sprint.find(@options[:sprint_id]) unless @options[:sprint_id].nil?

      if items_only?
        @elements = fetch_items_dependant_on_context
      elsif tasks_only?
        @elements = Task.for_cards(@sprint.id) if @options[:context] == 'sprint'
      elsif both?
        @elements = []
        @items = fetch_items_dependant_on_context
        @items.each do |item|
          @elements << item
          if item.tasks.size > 0
            item.tasks.each {|t| @elements << t}
          end
        end
      end

      if @elements.size > 0
        @generator = CardGenerator.new(@elements, @options)
        pdf_data = @generator.generate_output

        create_index_card_log

        send_data(pdf_data, {:filename => "index_cards.pdf", :type => "application/pdf"})
      else 
        flash[:error] = "No elements to be rendered as index cards"
        redirect_to :back
      end

    rescue Exception => e
      flash[:error] = "Unable to generate index cards: #{e.message}"
      redirect_to :back
    end
  end

  protected
  def fetch_items_dependant_on_context
    if @options[:context] == 'sprint'
      items = @sprint.items
    else 
      items = Project.current.items.not_assigned
    end
    return items
  end

  def items_only?
    @options[:contents].nil? || @options[:contents] == 'items'
  end

  def tasks_only?
    @options[:contents] == 'tasks'
  end

  def both?
    @options[:contents] == 'all'
  end

  def create_index_card_log 
    log = IndexCardLog.new(:domain => Domain.current)
    log.collection_size = @elements.size
    log.contents = @options[:contents]
    log.context = @options[:context] unless @options[:context].nil?
    log.save
  end

  def parse_options(params)
    options = {}
    available_options = %w(paper orientation contents sprint_id context project_id)
    available_options.each do |option|
      options[option.to_sym] = params[option] unless params[option].nil?
    end
    return options
  end

  def xhr_only
    unless request.xhr?
        flash[:warning] = "The page you are looking for doesn't exist"
        redirect_to root_url
    end
  end
end

module InPlaceEditing
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Example:
  #
  #   # Controller
  #   class BlogController < ApplicationController
  #     in_place_edit_for :post, :title
  #   end
  #
  #   # View
  #   <%= in_place_editor_field :post, 'title' %>
  #
  #
  # Information regarding html vs plain text.
  #   
  #    The helper automatically escapes initial value - see helper documentation for more details
  #    Wrt. to data returned by loadTextURL - it MUST NOT be html escaped
  #    Wrt. to data returned by the remote function - it MUST be html escaped
  #
  #   
  # Using different methods to read and write data:
  # 
  #   If you really need such possibilities, there are :reader_attr  and writer_attr options,
  #   they default to "#{attribute}" and "#{attribute}=" respectively.
  
  module ClassMethods
    def in_place_edit_for(object, attribute, options = {})
      reader_attr = options.delete(:reader_attr) || attribute
      writer_attr = ((options.delete(:writer_attr) || attribute).to_s + '=').to_sym
      
      define_method("#{object}_#{attribute}") do
        unless [:post, :put].include?(request.method) then
          return render :text => 'Method not allowed', :status => 405
        end
        
        @item = object.to_s.camelize.constantize.find(params[:id])
        old_value = @item.send(reader_attr)
        
        @item.send(writer_attr, params[:value])
        status = 200
        
        @return_value = if @item.save
          @item.send(reader_attr).to_s
        else
          flash[:error] = @item.errors.full_messages.join("\n")
          status = 409
          old_value
        end
        
        return render_json status, :item => @item.id, :value => @return_value
      end
    end
  end
end

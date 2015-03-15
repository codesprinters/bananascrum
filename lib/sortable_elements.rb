#
# Module that provides helper method for sorting elements, which are in
# relation to it.
#
module SortableElements
  
  class Base 
    def after_update(object)
      if has_scope?(object.attributes)
        if scope(old_attributes(object)) != scope(object.attributes) || !has_scope?(old_attributes(object)) # scope changed or was entered
          sort_elements(object.class.quoted_table_name, object.attributes, object.send("#{position_attribute.to_s}"), nil)
          fix_order(object.class.quoted_table_name, scope(old_attributes(object))) if has_scope?(old_attributes(object))
        elsif object.send("#{position_attribute.to_s}_changed?")
          sort_elements(object.class.quoted_table_name, object.attributes, object.send("#{position_attribute.to_s}"), object.send("#{position_attribute.to_s}_was"))
        end
      else
        if has_scope?(old_attributes(object))
          fix_order(object.class.quoted_table_name, scope(old_attributes(object)))
          object.class.update_all("#{position_attribute} = NULL", :id => object.id)
        end 
      end
    end

    def after_create(object)
      if has_scope?(object.attributes)
        sort_elements(object.class.quoted_table_name, object.attributes, object.send("#{position_attribute.to_s}"))
      end
    end

    def after_destroy(object)
      if has_scope?(object.attributes)
        fix_order(object.class.quoted_table_name, scope(object.attributes))
      end
    end
    
    def self.disable_callbacks(&block)
      Thread.current[flag_name] = true
      return block.call
    ensure
      Thread.current[flag_name] = false
    end

    def disabled?
      return Thread.current[self.class.flag_name]
    end

    protected
    def self.flag_name
      return (self.to_s.underscore + "_callbacks_disabled").to_sym
    end
    
    def scope(attributes)
      raise "This method has to be overloaded!"
    end

    def has_scope?(attributes)
      raise "This method has to be overloaded!"
    end

    def position_attribute
      raise "This method has to be overloaded!"
    end

    def scope_without_me(attributes)
      "#{scope(attributes)} AND id != #{attributes['id']}"
    end


    def scope_changed?(object)
      return scope(object.attributes) != scope(old_attributes(object))
    end
    
    def old_attributes(object)
      res = Hash.new
      object.attributes.keys.each { |k| res[k] = object.send("#{k.to_s}_was") }
      res
    end

    def sort_elements(table_name, attributes, desired_position = nil, position_was = nil)
      if desired_position
        desired_position = desired_position.to_i
        desired_position = 0 if desired_position < 0
  
        sql = nil
        if position_was.nil?
          sql = "UPDATE #{table_name}
            SET #{position_attribute} = #{position_attribute} + 1 
            WHERE #{position_attribute} IS NOT NULL AND #{position_attribute} >= #{desired_position} AND #{scope_without_me(attributes)}"
        elsif desired_position > position_was
          sql = "UPDATE #{table_name} 
            SET #{position_attribute} = #{position_attribute} - 1 
            WHERE #{position_attribute} IS NOT NULL AND #{position_attribute} > #{position_was} AND #{position_attribute} <= #{desired_position} AND #{scope_without_me(attributes)}"
        elsif desired_position < position_was
          sql = "UPDATE #{table_name}
            SET #{position_attribute} = #{position_attribute} + 1 
            WHERE #{position_attribute} IS NOT NULL AND (#{position_attribute} < #{position_was} AND #{position_attribute} >= #{desired_position}) AND #{scope_without_me(attributes)}"
        end
        ActiveRecord::Base.connection.execute(sql) if sql
      end
      fix_order(table_name, scope(attributes))
    end

    # Executes update query on collection, defined by scope, to make sure it is set in
    # correct order.
    # After running this query and reloading collection, each element will
    # have position numbered from 0 to N - 1, where N is number of elements in
    # that collection
    def fix_order(table_name, current_scope)
      ActiveRecord::Base.connection.execute('SET @rownum := -1')
      sql = "UPDATE #{table_name}
        SET #{position_attribute} = @rownum := @rownum + 1 WHERE #{current_scope}
        ORDER BY ISNULL(#{position_attribute}),#{position_attribute} ASC"
      ActiveRecord::Base.connection.execute(sql, "Fix ordering #{table_name}")
    end

  end

  module Mixins
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def acts_as_sortable(manager)
        klass = manager.is_a?(Class) ? manager : Object.const_get(manager.to_s.classify)
        instance = klass.new
        after_create instance, :if => Proc.new { !instance.disabled? }
        after_update instance, :if => Proc.new { !instance.disabled? }
        after_destroy instance, :if => Proc.new { !instance.disabled? }
      end
    end
  end
end

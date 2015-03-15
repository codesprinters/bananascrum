module LimitAccess

  def limit_access(role_code, args)
    args.to_options!.assert_valid_keys(:only, :except, :none, :if)

    # Accessor for access table as instance variable of the class
    meta = (class << self; self; end)
    unless meta.instance_methods.include?("limit_access_table")
      meta.class_eval do
        attr_accessor_with_default :limit_access_table, Hash.new
      end
    end

    # Add to access table
    limit_access_table[role_code] = args

    # Connect filter method if not already connected
    unless instance_methods.include?("limit_access_filter")
      protected
      define_method :limit_access_check do |role_code|
        if self.class.limit_access_table.has_key?(role_code)
          args = self.class.limit_access_table[role_code]
          if !args[:if] || args[:if].call(self)
            case
            when args.keys.include?(:none)
              false
            when args.keys.include?(:only)
              args[:only].include?(action_name.to_sym)
            when args.keys.include?(:except)
              !args[:except].include?(action_name.to_sym)
            end
          else
            true
          end
        else
          # Unlimited role
          true
        end
      end

      define_method :limit_access_filter do
        return if Project.current.nil? || User.current.nil?

        # Check if any role lets the current user in
        allow = Project.current.get_user_roles(User.current).map(&:code).map(&:to_sym).map do |role_code|
          limit_access_check(role_code)
        end.any?

        unless allow || User.current.admin?
          message = "Access denied for this action"
          if request.xhr?
            render_json 403, :_error => { :type => 'limit_access', :message => message }
          else
            flash[:warning] = message
            redirect_to(request.env["HTTP_REFERER"] || "/")
          end
        end
      end
      before_filter :limit_access_filter
    end
  end

end

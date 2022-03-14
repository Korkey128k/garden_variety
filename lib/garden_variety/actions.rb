module GardenVariety

  REDIRECT_CODES = [301, 302, 303, 307, 308].to_set

  module IndexAction
    # Garden variety controller +index+ action.
    # @return [void]
    def index
      authorize(self.class.model_class)
      self.collection = policy_scope(find_collection)
    end
  end

  module ShowAction
    # Garden variety controller +show+ action.
    # @return [void]
    def show
      self.model = authorize(find_model)
    end
  end

  module NewAction
    # Garden variety controller +new+ action.
    # @return [void]
    def new
      self.model = (model = authorize(new_model))
      assign_attributes(model) if params.key?(self.class.model_name.param_key)
    end
  end

  module CreateAction
    # Garden variety controller +create+ action.
    # @overload create()
    # @overload create()
    #   @yield on-success callback, replaces default redirect
    # @return [void]
    def create
      self.model = (model = assign_attributes(authorize(new_model)))
      if model.save
        flash[:success] = flash_message(:success)
        block_given? ? yield : redirect_to(model)
        flash.discard(:success) if REDIRECT_CODES.exclude?(response.status)
      else
        flash[:error] = flash_message(:error)
        redirect_back fallback_location: model
      end
    end
  end

  module EditAction
    # Garden variety controller +edit+ action.
    # @return [void]
    def edit
      self.model = authorize(find_model)
    end
  end

  module UpdateAction
    # Garden variety controller +update+ action.
    # @overload update()
    # @overload update()
    #   @yield on-success callback, replaces default redirect
    # @return [void]
    def update
      self.model = (model = assign_attributes(authorize(find_model)))
      if model.save
        flash[:success] = flash_message(:success)
        block_given? ? yield : redirect_to(model)
        flash.discard(:success) if REDIRECT_CODES.exclude?(response.status)
      else
        flash[:error] = flash_message(:error)
        redirect_back fallback_location: model
      end
    end
  end

  module DestroyAction
    # Garden variety controller +destroy+ action.
    # @overload destroy()
    # @overload destroy()
    #   @yield on-success callback, replaces default redirect
    # @return [void]
    def destroy
      self.model = (model = authorize(find_model))
      if model.destroy
        flash[:success] = flash_message(:success)
        block_given? ? yield : redirect_to(action: :index)
        flash.discard(:success) if REDIRECT_CODES.exclude?(response.status)
      else
        flash[:error] = flash_message(:error)
        redirect_back fallback_location: {action: :index}
      end
    end
  end

  # Map of controller action name to action module.  Used by the
  # {GardenVariety::Controller::ClassMethods#garden_variety
  # garden_variety} macro to include desired controller actions.
  ACTION_MODULES = {
    index: IndexAction,
    show: ShowAction,
    new: NewAction,
    create: CreateAction,
    edit: EditAction,
    update: UpdateAction,
    destroy: DestroyAction,
  }

end

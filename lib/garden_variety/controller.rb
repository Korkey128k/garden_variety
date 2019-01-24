module GardenVariety
  module Controller
    extend ActiveSupport::Concern

    include Pundit

    module ClassMethods
      # Macro to include garden variety implementations of specified
      # actions in the controller.  If no actions are specified, all
      # typical REST actions (index, show, new, create, edit, update,
      # destroy) are included.
      #
      # See also:
      # - {GardenVariety::IndexAction}
      # - {GardenVariety::ShowAction}
      # - {GardenVariety::NewAction}
      # - {GardenVariety::CreateAction}
      # - {GardenVariety::EditAction}
      # - {GardenVariety::UpdateAction}
      # - {GardenVariety::DestroyAction}
      #
      # @example default usage
      #   # This...
      #   class PostsController < ApplicationController
      #     garden_variety
      #   end
      #
      #   # ...is equivalent to:
      #   class PostsController < ApplicationController
      #     include GardenVariety::IndexAction
      #     include GardenVariety::ShowAction
      #     include GardenVariety::NewAction
      #     include GardenVariety::CreateAction
      #     include GardenVariety::EditAction
      #     include GardenVariety::UpdateAction
      #     include GardenVariety::DestroyAction
      #   end
      #
      # @example specific usage
      #   # This...
      #   class PostsController < ApplicationController
      #     garden_variety :index, :show
      #   end
      #
      #   # ...is equivalent to:
      #   class PostsController < ApplicationController
      #     include GardenVariety::IndexAction
      #     include GardenVariety::ShowAction
      #   end
      #
      # @param actions [Array<:index, :show, :new, :create, :edit, :update, :destroy>]
      # @return [void]
      def garden_variety(*actions)
        action_modules = actions.empty? ?
          ::GardenVariety::ACTION_MODULES.values :
          ::GardenVariety::ACTION_MODULES.values_at(*actions)

        action_modules.each{|m| include m }
      end

      # Returns the controller model class.  Defaults to a class
      # corresponding to the singular-form of the controller name.
      #
      # @example
      #   class PostsController < ApplicationController
      #   end
      #
      #   PostsController.model_class  # == Post (class)
      #
      # @return [Class]
      def model_class
        @model_class ||= controller_path.classify.constantize
      end

      # Sets the controller model class.
      #
      # @example
      #   class PublishedPostsController < ApplicationController
      #     self.model_class = Post
      #   end
      #
      # @param klass [Class]
      # @return [klass]
      def model_class=(klass)
        @model_class = klass
      end
    end

    private

    # @!visibility public
    # Returns the value of the singular-form instance variable dictated
    # by {::model_class}.
    #
    # @example
    #   class PostsController
    #     def show
    #       # This...
    #       self.model
    #       # ...is equivalent to:
    #       @post
    #     end
    #   end
    #
    # @return [Object]
    def model
      instance_variable_get("@#{self.class.model_class.to_s.underscore.tr("/", "_")}")
    end

    # @!visibility public
    # Sets the value of the singular-form instance variable dictated
    # by {::model_class}.
    #
    # @example
    #   class PostsController
    #     def show
    #       # This...
    #       self.model = value
    #       # ...is equivalent to:
    #       @post = value
    #     end
    #   end
    #
    # @param value [Object]
    # @return [value]
    def model=(value)
      instance_variable_set("@#{self.class.model_class.to_s.underscore.tr("/", "_")}", value)
    end

    # @!visibility public
    # Returns the value of the plural-form instance variable dictated
    # by {::model_class}.
    #
    # @example
    #   class PostsController
    #     def index
    #       # This...
    #       self.collection
    #       # ...is equivalent to:
    #       @posts
    #     end
    #   end
    #
    # @return [Object]
    def collection
      instance_variable_get("@#{self.class.model_class.to_s.tableize.tr("/", "_")}")
    end

    # @!visibility public
    # Sets the value of the plural-form instance variable dictated
    # by {::model_class}.
    #
    # @example
    #   class PostsController
    #     def index
    #       # This...
    #       self.collection = values
    #       # ...is equivalent to:
    #       @posts = values
    #     end
    #   end
    #
    # @param values [Object]
    # @return [values]
    def collection=(values)
      instance_variable_set("@#{self.class.model_class.to_s.tableize.tr("/", "_")}", values)
    end

    # @!visibility public
    # Returns an ActiveRecord::Relation representing model instances
    # corresponding to the controller.  Designed for use in generic
    # +index+ action methods.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def index
    #        @posts = find_collection.where(status: "published")
    #     end
    #   end
    #
    # @return [ActiveRecord::Relation]
    def find_collection
      self.class.model_class.all
    end

    # @!visibility public
    # Returns a model instance corresponding to the controller and the
    # id parameter of the current request (i.e. +params[:id]+).
    # Designed for use in generic +show+, +edit+, +update+, and
    # +destroy+ action methods.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def show
    #        @post = find_model
    #     end
    #   end
    #
    # @return [ActiveRecord::Base]
    def find_model
      self.class.model_class.find(params[:id])
    end

    # @!visibility public
    # Returns a new model instance corresponding to the controller.
    # Designed for use in generic +new+ and +create+ action methods.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def new
    #        @post = new_model
    #     end
    #   end
    #
    # @return [ActiveRecord::Base]
    def new_model
      self.class.model_class.new
    end

    # @!visibility public
    # Authorizes the given model for the current action via the model
    # Pundit policy, and populates the model attributes with the current
    # request params permitted by the model policy.  Returns the given
    # model modified but not persisted.
    #
    # @example
    #   class PostsController < ApplicationController
    #     def create
    #       @post = vest(Post.new)
    #       if @post.save
    #         redirect_to @post
    #       else
    #         render :new
    #       end
    #     end
    #   end
    #
    # @param model [ActiveRecord::Base]
    # @return [ActiveRecord::Base]
    def vest(model)
      authorize(model)
      model.assign_attributes(permitted_attributes(model))
      model
    end

    # @!visibility public
    # Returns Hash of values for interpolation in flash messages via
    # I18n.  By default, returns +resource_name+ and
    # +resource_capitalized+ values appropriate to the controller.
    # Override this method to provide your own values.  Be aware that
    # certain option names, such as +default+ and +scope+, are reserved
    # by the I18n gem, and can not be used for interpolation.  See the
    # {https://www.rubydoc.info/gems/i18n I18n documentation} for more
    # information.
    #
    # @return [Hash]
    def flash_options
      { resource_name: self.class.model_class.model_name.human.downcase,
        resource_capitalized: self.class.model_class.model_name.human }
    end

    # @!visibility public
    # Returns a flash message appropriate to the controller, the current
    # action, and a given status.  The flash message is looked up via
    # I18n using a prioritized list of possible keys.  The key priority
    # is as follows:
    #
    # * +{controller_name}.{action_name}.{status}+
    # * +{controller_name}.{action_name}.{status}_html+
    # * +{action_name}.{status}+
    # * +{action_name}.{status}_html+
    # * +{status}+
    # * +{status}_html+
    #
    # If the controller is namespaced, the namespace will prefix
    # (dot-separated) the +{controller_name}+ portion of the key.
    #
    # I18n string interpolation can be used in flash messages, with
    # interpolated values provided by the {flash_options} method.
    #
    # @example Key priority
    #   ### config/locales/garden_variety.en.yml
    #   # en:
    #   #   success: "Success!"
    #   #   create:
    #   #     success: "%{resource_capitalized} created."
    #   #   delete:
    #   #     success: "%{resource_capitalized} deleted."
    #   #   posts:
    #   #     create:
    #   #       success: "Congratulations on your new post!"
    #
    #   # via PostsController#create
    #   flash_message(:success)  # == "Congratulations on your new post!"
    #
    #   # via PostsController#update
    #   flash_message(:success)  # == "Success!"
    #
    #   # via PostsController#delete
    #   flash_message(:success)  # == "Post deleted."
    #
    # @example Namespaced controller
    #   ### config/locales/garden_variety.en.yml
    #   # en:
    #   #   create:
    #   #     success: "Created new %{resource_name}."
    #   #   update:
    #   #     success: "Updated %{resource_name}."
    #   #   messages:
    #   #     drafts:
    #   #       update:
    #   #         success: "Draft saved."
    #
    #   # via Messages::DraftsController#create
    #   flash_message(:success)  # == "Created new draft."
    #
    #   # via Messages::DraftsController#update
    #   flash_message(:success)  # == "Draft saved."
    #
    # @param status [Symbol, String]
    # @return [String]
    def flash_message(status)
      controller_key = controller_path.tr("/", I18n.default_separator)
      keys = [
        :"#{controller_key}.#{action_name}.#{status}",
        :"#{controller_key}.#{action_name}.#{status}_html",
        :"#{action_name}.#{status}",
        :"#{action_name}.#{status}_html",
        :"#{status}",
        :"#{status}_html",
      ]
      helpers.translate(keys.shift, default: keys, **flash_options)
    end
  end
end

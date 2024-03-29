# frozen_string_literal: true

require 'ostruct'

module GL
  class NotAContextError < ArgumentError; end

  class Context < OpenStruct # rubocop:disable Style/OpenStructUse
    include ActiveModel::Validations

    attr_accessor :errors

    def self.factory(context = {})
      return context if context.is_a?(Context)
      raise NotAContextError, 'Arguments are not a Context.' unless context.respond_to?(:each_pair)

      Context.new(context)
    end

    def initialize(args)
      super(args)
      @errors = ActiveModel::Errors.new(self)
    end

    def fail!
      @failure = true
    end

    def failure?
      @failure || false
    end

    def success?
      !failure?
    end
    alias_method :successful?, :success?

    def inspect
      "<GL::Context success:#{success?} errors:#{@errors.full_messages} data:#{to_h}>"
    end
  end
end

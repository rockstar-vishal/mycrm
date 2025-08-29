module Notifications

  class LiquidMdTemplate

    attr_reader :content,
      :variables

    def initialize(content, variables)
      @content = content
      @variables = variables
    end

    def render(type)
      LiquidMarkdown::Render.new(content, variables).send(type) if content
    end

  end

end

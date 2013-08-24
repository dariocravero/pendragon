require 'mustermann'

class Howl
  class Matcher
    def initialize(path, options = {})
      @path           = path.is_a?(String) && path.empty? ? "/" : path
      @capture        = options.delete(:capture)
      @default_values = options.delete(:default_values)
    end

    def match(pattern)
      handler.match(pattern)
    end

    def expand(params)
      params = params.dup
      query = params.keys.inject({}) do |result, key|
        result[key] = params.delete(key) if !handler.names.include?(key.to_s)
        result
      end
      params.merge!(@default_values) if @default_values.is_a?(Hash)
      expanded_path = handler.expand(params)
      expanded_path = expanded_path + "?" + query.map{|k,v| "#{k}=#{v}" }.join("&") unless query.empty?
      expanded_path
    end

    def mustermann?
      handler.class == Mustermann::Rails
    end

    def handler
      @handler ||= case @path
                   when String then Mustermann.new(@path, :type => :rails, :capture => @capture)
                   when Regexp then /^(?:#{@path})$/
                   end
    end

    def to_s
      handler.to_s
    end

    def names
      mustermann? ? handler.names.map(&:to_sym) : []
    end
  end
end

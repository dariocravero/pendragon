module Pendragon
  class Route

    # The accessors are useful to access from Pendragon::Router
    attr_accessor :name, :capture, :order, :options

    # For compile option
    attr_accessor :index

    # The verb should be read from Pendragon::Router
    attr_reader :verb, :block

    # The router will be treated in this class.
    attr_writer :router

    # Constructs a new instance of Pendragon::Route
    def initialize(path, verb, options = {}, &block)
      @block = block if block_given?
      @path, @verb = path, verb
      @capture = {}
      @order = 0
      merge_with_options!(options)
    end

    def matcher
      @matcher ||= Matcher.new(@path, :capture        => @capture,
                                      :default_values => options[:default_values])
    end

    def arity
      @block.arity
    end

    def call(*args)
      @block.call(*args)
    end

    def match(pattern)
      matcher.match(pattern)
    end

    def to(&block)
      @block = block if block_given?
      @order = @router.current
      @router.increment_order!
    end

    def path(*args)
      return @path if args.empty?
      params = args[0]
      params.delete(:captures)
      matcher.expand(params) if matcher.mustermann?
    end

    def params(pattern, parameters = {})
      match_data, params = match(pattern), {}
      if match_data.names.empty?
        params.merge!(:captures => match_data.captures) unless match_data.captures.empty?
        params
      else
        params = matcher.handler.params(pattern, :captures => match_data) || params
        symbolize(params).merge(parameters){|key, old, new| old || new }
      end
    end

    def symbolize(parameters)
      parameters.inject({}){|result, (key, val)| result[key.to_sym] = val; result }
    end

    def merge_with_options!(options)
      @options = {} unless @options
      options.each_pair do |key, value|
        accessor?(key) ? __send__("#{key}=", value) : (@options[key] = value)
      end
    end

    def accessor?(key)
      respond_to?("#{key}=") && respond_to?(key)
    end

    private :symbolize, :merge_with_options!, :accessor?
  end
end

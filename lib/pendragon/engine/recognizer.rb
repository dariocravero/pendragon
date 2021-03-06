module Pendragon
  class Recognizer
    def initialize(routes)
      @routes = routes
    end

    def call(request)
      pattern, verb, params = parse_request(request)
      raise_exception(400) unless valid_verb?(verb)
      fetch(pattern, verb){|route| [route, params_for(route, pattern, params)] }
    end

    private

    # @!visibility private
    def params_for(route, pattern, params)
      route.params(pattern, params)
    end

    # @!visibility private
    def valid_verb?(verb)
      Pendragon::HTTP_VERBS.include?(verb.downcase.to_sym)
    end

    # @!visibility private
    def fetch(pattern, verb)
      _routes = @routes.select{|route| route.match(pattern) }
      raise_exception(404) if _routes.empty?
      result = _routes.map{|route| yield(route) if verb == route.verb }.compact
      raise_exception(405, :verbs => _routes.map(&:verb)) if result.empty?
      result
    end

    # @!visibility private
    def parse_request(request)
      if request.is_a?(Hash)
        [request['PATH_INFO'], request['REQUEST_METHOD'].downcase.to_sym, {}]
      else
        [request.path_info, request.request_method.downcase.to_sym, parse_request_params(request.params)]
      end
    end

    # @!visibility private
    def parse_request_params(params)
      params.inject({}) do |result, entry|
        result[entry[0].to_sym] = entry[1]
        result
      end
    end

    # @!visibility private
    def raise_exception(error_code, options = {})
      raise ->(error_code) {
        case error_code
        when 400
          BadRequest
        when 404
          NotFound
        when 405
          MethodNotAllowed.new(options[:verbs])
        end
      }.(error_code)
    end
  end
end

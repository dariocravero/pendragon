require File.expand_path('../../lib/pendragon', __FILE__)
$:.unshift(File.dirname(__FILE__))
require 'helper'

describe Pendragon::Configuration do
  setup{ ENABLE_COMPILER = false; @pendragon = pendragon }
  teardown{ Pendragon.reset_configuration! }

  describe "auto_rack_format" do
    should "set `true` as default value" do
      @pendragon.get("/"){ "hey" }
      get "/"
      assert_equal "hey", body
      assert_equal true, @pendragon.configuration.auto_rack_format?
    end

    should "not serialize for rack format if `auto_rack_format` is false" do
      @pendragon = pendragon do |config|
        config.auto_rack_format = false
      end

      p @pendragon.configuration.auto_rack_format?
      @pendragon.get("/"){ "hey" }
      get "/"
      p body
      assert_raises(Rack::Lint::LintError){ get "/" }

      @pendragon.post("/"){ [200, {'Content-Type' => 'text/html;charset=utf-8'}, ["hey"]] }
      post "/"
      assert_equal "hey", body
      assert_equal false, @pendragon.configuration.auto_rack_format?
    end
  end
end

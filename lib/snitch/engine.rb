module Snitch
  class Engine < ::Rails::Engine
    isolate_namespace Snitch

    initializer "snitch.middleware" do |app|
      app.middleware.insert_after ActionDispatch::DebugExceptions, Snitch::Middleware
    end
  end
end

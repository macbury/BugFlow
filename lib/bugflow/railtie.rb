require "rails"
if defined?(Rails)

  module BugFlow
    class Railtie < Rails::Railtie
      initializer "cloud_monitor" do |app|
        app.config.middleware.use "BugFlow::Middleware"
      end

      rake_tasks do
        #Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f }
      end
    end
  end

end

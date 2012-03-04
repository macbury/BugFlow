module BugFlow
  class Error              < StandardError ; end
  class ConfigurationError < Error         ; end
  class DeliveryError      < Error         ; end
end

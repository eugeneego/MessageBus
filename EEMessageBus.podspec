Pod::Spec.new do |s|
  s.name         = "EEMessageBus"
  s.version      = "1.0.0"
  s.summary      = "Simple message bus for Objective-C."
  s.homepage     = "https://github.com/eugeneego/MessageBus"
  s.license      = "MIT"
  s.author       = "Evgeniy Egorov"
  s.platform     = :ios, "5.0"
  s.source       = { :git => "https://github.com/eugeneego/MessageBus.git", :tag => "#{s.version}" }
  s.source_files  = "EEMessageBus/*.{h,m,c}"
  s.requires_arc = true
end

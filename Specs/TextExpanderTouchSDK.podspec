Pod::Spec.new do |s|
  s.name = 'TextExpanderTouchSDK'
  s.version = '2.1'
	s.platform = :ios
  s.source = { :git => 'https://github.com/SmileSoftware/TextExpanderTouchSDK.git' }
  s.requires_arc = true
  s.ios.vendored_frameworks = 'TextExpander.framework'
	s.frameworks = 'AudioToolbox', 'CoreGraphics', 'CoreText', 'EventKit', 'Foundation', 'UIKit'
	s.resources = 'Default.textexpander'
end

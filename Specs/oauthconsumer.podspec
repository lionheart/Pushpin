Pod::Spec.new do |s|
  s.name = 'oauthconsumer'
  s.version = '0.0.1'
  s.source = { :git => 'https://github.com/jdg/oauthconsumer.git' }
  s.requires_arc = false
  s.source_files = 'Crypto/*.{c,h}', 'Categories/*.{h,m}', '*.{h,m}'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(SDKROOT)/usr/include/libxml2"' }
  s.ios.framework = 'Security'
end


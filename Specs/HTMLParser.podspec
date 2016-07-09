Pod::Spec.new do |s|
  s.name = 'HTMLParser'
  s.version = '0.0.1'
  s.homepage = ""
  s.summary = ""
  s.source = { :git => 'https://github.com/zootreeves/Objective-C-HMTL-Parser.git' }
  s.requires_arc = true
  s.source_files = '*.{h,m}'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(SDKROOT)/usr/include/libxml2"' }
end

Pod::Spec.new do |s|
  s.name = 'HTMLParser'
  s.version = '0.0.1'
  s.source = { :git => 'https://github.com/zootreeves/Objective-C-HMTL-Parser' }
  s.requires_arc = true
  s.source_files = '*.{h,m}'
  # s.libraries = 'xml2'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(SDKROOT)/usr/include/libxml2"' }
end

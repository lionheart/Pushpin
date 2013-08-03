Pod::Spec.new do |s|
  s.name = 'BloomFilter'
  s.version = '0.0.1'
  s.source = { :git => 'https://github.com/rgerard/ios-bloom-filter.git' }
  s.requires_arc = true
  s.source_files = 'BloomFilter/*.{h,m}'
end

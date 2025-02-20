Pod::Spec.new do |s|
  s.name         = "LHSCategoryCollection"
  s.version      = "0.0.4"
  s.summary      = "A collection of categories I commonly use in iOS projects."
  s.homepage     = "lionheartsw.com"
  s.license      = 'Apache 2.0'
  s.author       = { "Dan Loewenherz" => "dan@lionheartsw.com" }
  s.source       = { :git => "https://github.com/lionheart/LHSCategoryCollection.git", :commit => "6a88d2a" }

  s.source_files = '*.{h,m}'
  s.public_header_files = '*.h'
  s.requires_arc = true
end


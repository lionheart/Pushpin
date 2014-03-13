Pod::Spec.new do |s|
  s.name         = "LHSCustomTransitionCollection"
  s.version      = "0.0.1"
  s.homepage     = "lionheartsw.com"
  s.license      = 'Apache 2.0'
  s.author       = { "Dan Loewenherz" => "dan@lionheartsw.com" }
  s.source       = { :git => "https://github.com/lionheart/LHSCustomTransitionCollection.git" }

  s.source_files = 'Sources/**/*.{h,m}'
  s.requires_arc = true
end


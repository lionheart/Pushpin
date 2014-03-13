Pod::Spec.new do |s|
  s.name         = "LHDelicious"
  s.version      = "0.0.1"
  s.homepage     = "lionheartsw.com"
  s.license      = 'Apache 2.0'
  s.author       = { "Andy Muldowney" => "andy@lionheartsw.com" }
  s.source       = { :git => "https://github.com/lionheart/LHDelicious.git" }

  s.source_files = 'LHDelicious/*.{h,m}'
  s.requires_arc = true
  s.dependency 'XMLDictionary', '~> 1.3'
  s.dependency 'AFNetworking', '~> 1.3.2'
end


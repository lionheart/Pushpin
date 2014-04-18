Pod::Spec.new do |s|
  s.name         = "LHSDiigo"
  s.version      = "0.0.1"
  s.summary      = ""
  s.license      = "Apache 2.0"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Dan Loewenherz" => "dan@lionheartsw.com" }
  s.social_media_url   = "http://twitter.com/dwlz"

  s.platform     = :ios, "7.0"
  s.source       = { :git => "http://github.com/lionheart/LHSDiigo.git", :tag => "0.0.1" }

  s.source_files  = "LHSDiigo", "LHSDiigo/*.{h,m}"
  s.requires_arc = true
end

Pod::Spec.new do |s|
  s.name         = "ADNActivityCollection"
  s.version      = "0.0.1"
  s.license      = 'BSD'
  s.source       = { :git => "https://github.com/lionheart/ADNActivityCollection.git", :commit => "df29a71" }
  s.source_files = 'ADNActivities/*.{h,m}'
  s.public_header_files = 'ADNActivities/*.h'
  s.requires_arc = true
end



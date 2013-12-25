Pod::Spec.new do |s|
  s.name         = "LHSCategoryCollection"
  s.version      = "0.0.4"
  s.summary      = "A collection of categories I commonly use in iOS projects."
  s.homepage     = "lionheartsw.com"
  s.license      = 'Apache 2.0'
  s.author       = { "Dan Loewenherz" => "dan@lionheartsw.com" }
  s.source       = { :git => "https://github.com/lionheart/LHSCategoryCollection.git", :commit => "8ca9104" }

  s.source_files = '*.{h,m}'
  s.public_header_files = '*.h'
  s.requires_arc = true
  s.pre_install do |pod, target_definition|
    system "find . | grep FMDatabase.h"

    if true
    # if $?.exitstatus == 1
      Dir.chdir(pod.root) do
        system "rm FMDatabase+*"
      end
    end
  end
end


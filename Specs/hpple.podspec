Pod::Spec.new do |s|
  s.name         = "hpple"
  s.version      = "0.3.0"
  s.summary      = "An XML/HTML parser for Objective-C, inspired by Hpricot."
  s.description  = <<-DESC
Hpple: A nice Objective-C wrapper on the XPathQuery library for parsing HTML.
Inspired by why the lucky stiff's Hpricot.

* Easy searching by XPath (CSS selectors are planned)
* Parses HTML (XML coming soon)
* Easy access to tag content, name, and attributes
                   DESC
  s.homepage     = "https://github.com/topfunky/hpple"
  s.license      = 'MIT'
  s.author       = { "Geoffrey Grosenbach" => "email@address.com" }
  s.source       = { :git => "https://github.com/topfunky/hpple.git", :commit => "1429af59d75365ba26c32b2c0911dff31b9ab8c8" }
  s.source_files = 'TFHpple.{h,m}', 'TFHppleElement.{h,m}', 'XPathQuery.{h,m}'
  s.requires_arc = true
  s.library      = 'xml2'
  s.xcconfig     = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
end

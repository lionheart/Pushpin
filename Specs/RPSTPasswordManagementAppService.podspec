Pod::Spec.new do |s|
  s.name = 'RPSTPasswordManagementAppService'
  s.version = '0.0.1'
  s.license = { :file => 'LICENSE.md' }
  s.source = { :git => 'https://github.com/Riposte/RPSTPasswordManagementAppService.git' }
  s.requires_arc = true
  s.resources = ["Images/official-1pw-icon-set/*", "Images/official-1pw-icon-set/1P mono icons", "Images/riposte-icons/*"]
  s.source_files = '*.{h,m}'
end


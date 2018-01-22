Pod::Spec.new do |s|
  s.name             = 'Hohenheim'
  s.version          = "1.0.1"
  s.summary          = "An elegant image picker for iOS"
  s.homepage         = "https://github.com/Meniny/Hohenheim"
  s.license          = { :type => "MIT", :file => "LICENSE.md" }
  s.author           = 'Elias Abel'
  s.source           = { :git => "https://github.com/Meniny/Hohenheim.git", :tag => s.version.to_s }
  s.social_media_url = 'https://meniny.cn/'
  s.source_files     = "Hohenheim/**/*.swift"
  s.resources        = ['Hohenheim/Assets.xcassets', 'Hohenheim/**/*.xib']
  s.swift_version    = "4.0"
  s.requires_arc     = true
  s.ios.deployment_target = "10.0"
  s.description  = "Hohenheim is an elegant image picker for iOS"
  s.module_name = 'Hohenheim'
end

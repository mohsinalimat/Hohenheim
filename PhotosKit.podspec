Pod::Spec.new do |s|
  s.name             = 'PhotosKit'
  s.version          = "1.0.0"
  s.summary          = "An elegant image picker for iOS"
  s.homepage         = "https://github.com/Meniny/PhotosKit"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = 'Elias Abel'
  s.source           = { :git => "https://github.com/Meniny/PhotosKit.git", :tag => s.version.to_s }
  s.social_media_url = 'https://meniny.cn/'
  s.source_files     = "PhotosKit/**/*.swift"
  s.requires_arc     = true
  s.ios.deployment_target = "9.0"
  s.description  = "PhotosKit is an elegant image picker for iOS"
  s.module_name = 'PhotosKit'
end

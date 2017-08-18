Pod::Spec.new do |s|
  s.name         = "CNLDataProvider"
  s.version      = "0.0.7"
  s.summary      = "Basic model and data providers."
  s.description  = <<-DESC
Basic model and data providers for UITableView and UICollectionView
Commonly used in other Complex Numbers projects.
DESC
  s.homepage     = "https://github.com/megavolt605/CNLDataProvider"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Igor Smirnov" => "megavolt605@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/megavolt605/CNLDataProvider.git", :tag => "#{s.version}" }
  s.source_files  = "CNLDataProvider/**/*.{h,m,swift,map}"
  s.resources = "CNLDataProvider/*.xcassets"
  s.framework  = "Foundation", "UIKit", "CoreLocation"
  s.dependency "CNLFoundationTools" # , "~> 1.4"
  s.dependency "CNLUIKitTools" # , "~> 1.4"
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
end


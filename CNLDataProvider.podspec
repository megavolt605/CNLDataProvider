Pod::Spec.new do |s|
  s.name         = "CNLDataProvider"
  s.version      = "0.0.16"
  s.summary      = "Basic model and data providers."
  s.description  = <<-DESC
Basic model and data providers for UITableView and UICollectionView
Commonly used in other Complex Numbers projects.
DESC
s.homepage     = "https://github.com/megavolt605/#{s.name}"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Igor Smirnov" => "megavolt605@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/megavolt605/#{s.name}.git", :tag => "#{s.version}" }
  s.source_files  = "#{s.name}/**/*.{h,m,swift,map}"
  s.resources = "#{s.name}/*.xcassets"
  s.framework  = "Foundation", "UIKit", "CoreLocation"
  s.dependency "CNLFoundationTools" # , "~> 1.4"
  s.dependency "CNLUIKitTools" # , "~> 1.4"
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.1' }
end


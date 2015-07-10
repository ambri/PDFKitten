Pod::Spec.new do |s|
  s.name          = 'PDFKitten'
  s.version       = '1.1'
  s.platform      = :ios, '6.1'
  s.summary       = 'A framework for searching PDF documents on iOS.'
  s.homepage      = 'https://github.com/kotikan/PDFKitten'
  s.author        = "Marcus Hedenström"
  s.source        = { :git  => 'https://github.com/kotikan/PDFKitten.git' }
  s.license       = { :type => 'Public',
                      :text => %Q|This software is provided as is, meaning that we are not responsible for the results of its use.| }
  
  s.source_files = 'PDFKittenLib', 'PDFKittenLib/Core'
  s.requires_arc = true

end
Pod::Spec.new do |s|
  s.name          = 'PDFKitten'
  s.version       = '1.0'
  s.platform      = :ios, '5.0'
  s.summary       = 'A framework for searching PDF documents on iOS.'
  s.homepage      = ''
  s.author        = "Marcus Hedenström"
  s.source        = { :git  => 'git@github.com:ohdonpiano/PDFKitten.git' }
  s.license       = { :type => 'Public',
                      :text => %Q|This software is provided as is, meaning that we are not responsible for the results of its use.| }
  
  s.source_files = 'PDFKitten'
  s.requires_arc = false

end
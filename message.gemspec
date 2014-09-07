Gem::Specification.new do |s|
  s.name = 'message'
  s.version = '0.0.1'
  s.summary = 'Simplify Ruby messaging/queue/async/job processing.'
  s.description = <<-EOF
Message provides reliable background/asynchronous job processing mechanism on top of simple queue interface.
Also, Message provides an in-memory queue for making development and test easier.
EOF
  s.license = 'MIT'
  s.authors = ["Xiao Li"]
  s.email = ['swing1979@gmail.com']
  s.homepage = 'https://github.com/xli/message'

  s.files = ['README.md']
  s.files += Dir['lib/**/*.rb']
end

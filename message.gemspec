Gem::Specification.new do |s|
  s.name = 'message'
  s.version = '0.0.5'
  s.summary = 'Simplify Ruby messaging/queue/async/job processing.'
  s.description = <<-EOF
Message provides flexible & reliable background/asynchronous job processing mechanism on top of simple queue interface.

Any developer can create queue adapter for Message to hook up different messaging/queue system.

One in-memory queue is included with Message for you to start development and test,
and you can easily swap in other queues later.
EOF
  s.license = 'MIT'
  s.authors = ["Xiao Li"]
  s.email = ['swing1979@gmail.com']
  s.homepage = 'https://github.com/xli/message'

  s.files = ['README.md']
  s.files += Dir['lib/**/*.rb']
end

Jenkins::Plugin::Specification.new do |plugin|
  plugin.name = "pyenv"
  plugin.display_name = "pyenv plugin"
  plugin.version = '0.0.7git'
  plugin.description = 'Run Jenkins builds in pyenv'

  plugin.url = 'https://wiki.jenkins-ci.org/display/JENKINS/Pyenv+Plugin'
  plugin.developed_by "hsbt", "yamashita@geishatokyo.com"
  plugin.uses_repository :github => "yyuu/jenkins-pyenv-plugin"

  plugin.depends_on 'ruby-runtime', '0.10'
end

class dopki::sshagentadd(

  # class arguments
  # ---------------
  # setup defaults

  $user,
  $key_passphrase = '',
  $key_name = 'id_rsa'

  # end of class arguments
  # ----------------------
  # begin class

) {

  # install expect package and use for nested requisites
  anchor { 'dopki-sshagentadd-req' :
    require => $require,
  }

  file { 'bash-agent':
    path => "/home/${user}/.bash_sshagent",
    content => template('dopki/bash_sshagent.erb'),
    require => [Package['openssh-server'], Package['expect']],
    mode => 0700,
    owner => $user,
    group => $user,
  }

  # add include to .bashrc if unset, so this user gets agent when logging in
  #$command_bash_include_sshagent = "\n# pull in ssh_agent config if present\nif [ -f /home/${user}/.bash_sshagent ]; then\n        source /home/${user}/.bash_sshagent\nfi\n" 
  #concat::fragment { 'sshagent-bashrc-add':
  #  target  => "/home/${user}/.bashrc",
  #  content => $command_bash_include_sshagent,
  #  order   => '30',
  #  require => [File['bash-agent']],
  #}

  # create a cleanup file
  file { 'bash-agent-cleanup':
    path => "/home/${user}/.bash_sshagent_cleanup",
    content => template('dopki/bash_sshagent_cleanup.erb'),
    mode => 0700,
    owner => $user,
    group => $user,
  }

  # create autoload script to manually load new private key up into ssh-agent
  # key_passphrase used in template
  file { 'bash-agent-key' :
    path => "/home/${user}/.bash_keyautoload.tmp", 
    content => template('dopki/bash_keyautoload.erb'),
    require => Package['expect'],
    mode => 0700,
    owner => $user,
    group => $user,
  }

  # manually run the agent (for puppet install)
  exec { 'bash-add-agent-autoload':
    path => '/usr/bin:/bin:',
    cwd => "/home/${user}/",
    user => $user,
    provider => 'shell',
    command => "bash -c 'source /home/${user}/.bash_sshagent'",
    require => [Package['expect'], File['bash-agent-key'], File['bash-agent']],
  }
  
  # check to see if we've got loaded keys
  exec { 'bash-add-check':
    path => '/usr/bin:/bin:',
    cwd => "/home/${user}/",
    user => $user,
    provider => 'shell',
    command => "bash -c \"source /home/${user}/.ssh/environment; ssh-add -L | grep '.ssh/${key_name}'\"",
    require => Exec['bash-add-agent-autoload'],
  }
  
}

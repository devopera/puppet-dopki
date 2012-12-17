class dopki::sshagentadd(

  # class arguments
  # ---------------
  # setup defaults

  $user,
  $key, 
  $key_passphrase = 'admLn**',
  $key_type = 'rsa'

  # end of class arguments
  # ----------------------
  # begin class

) {

  # install expect package and use for nested requisites
  package { 'expect' :
    ensure => installed,
    require => $require,
  }

  file { 'ssh-id_xsa':
    path => "/home/${user}/.ssh/id_${key_type}",
    content => $key,
    mode => 0600,
    owner => $user,
    require => [Package['openssh'], Package['expect']],
  }

  file { 'bash-agent':
    path => "/home/${user}/.bash_sshagent",
    content => template('dopki/bash_sshagent.erb'),
    require => [Package['openssh-server'], File['ssh-id_xsa']],
    mode => 0700,
    owner => $user,
    group => $user,
  }

  # add include to .bashrc if unset, so this user gets agent when logging in
  exec { 'bash-add-agent':
    path => '/usr/bin:/bin:',
    cwd => "/home/${user}/",
    require => File['bash-agent'],
    command => "echo \"\n# pull in ssh_agent config \nsource /home/${user}/.bash_sshagent\" >> /home/${user}/.bashrc",
    onlyif => "grep -q 'source /home/${user}/.bash_sshagent' /home/${user}/.bashrc; test $? -eq 1",
  }

  # create a cleanup file
  file { 'bash-agent-cleanup':
    path => "/home/${user}/.bash_sshagent_cleanup",
    content => template('dopki/bash_sshagent_cleanup.erb'),
    require => Exec['bash-add-agent'],
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
    command => "bash -c \"source /home/${user}/.ssh/environment; ssh-add -L | grep '/home/${user}/.ssh/id_${key_type}'\"",
    require => Exec['bash-add-agent-autoload'],
  }
  
  notify { 'remember-to-source' :
    message => 'Remember to run "source .bashrc" to mimic normal login',
    require => Exec['bash-add-check'],
  }

}

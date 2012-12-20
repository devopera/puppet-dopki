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
  package { 'expect' :
    ensure => installed,
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
    command => "bash -c \"source /home/${user}/.ssh/environment; ssh-add -L | grep '/home/${user}/.ssh/${key_name}'\"",
    require => Exec['bash-add-agent-autoload'],
  }
  
  notify { 'remember-to-source' :
    message => 'Remember to run "source .bashrc" to mimic normal login',
    require => Exec['bash-add-check'],
  }

}

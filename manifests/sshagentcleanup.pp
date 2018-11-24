class dopki::sshagentcleanup(

  # class arguments
  # ---------------
  # setup defaults

  $user,

  # end of class arguments
  # ----------------------
  # begin class

) {

  # remove the key autoload file
  exec { 'bash-add-agent-autoload-delete':
    path => '/usr/bin:/bin:',
    cwd => "/home/${user}/",
    user => $user,
    provider => 'shell',
    command => "bash -c '/home/${user}/.bash_sshagent_cleanup'",
  }
  
  # alternatively ensure the autoload file is deleted
  #file { 'bash-agent-key-delete' :
  #  path => "/home/${user}/.bash_keyautoload.tmp", 
  #  ensure => absent,
  #}

}

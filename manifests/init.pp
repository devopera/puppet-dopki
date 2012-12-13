class dopki (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',
  $user_email = 'admin@example.com',

  # main user's public and private (with passphrase) keys
  $key_public = '',
  $key_private = '',
  $key_private_passphrase = '',
  $key_private_type = 'dsa',

  # end of class arguments
  # ----------------------
  # begin class

) {

  # authorised types have slightly different names to key types
  if ($key_private_type == 'dsa') {
    $key_authorized_type = 'dss'
  } else {
    $key_authorized_type = 'rsa'
  }

  # ensure that we've got a .ssh directory
  file { 'user-ssh-dir' :
    name   => "/home/${user}/.ssh",
    ensure => 'directory',
    owner  => $user,
    group  => $user,
    mode   => 700,
  }

  # if we have a public key
  if ($key_public != '') {
    # allow other machines to ssh to this one using standard key
    ssh_authorized_key { $user:
      ensure => present,
      key => $key_public,
      name => $user_email,
      user => $user,
      type => "ssh-${key_authorized_type}",
      require => File['user-ssh-dir'],
    }
    # also store in /home/<user>/.ssh/id_xsa.pub for continuity
    ssh_authorized_key { "extra-id_xsa-${user}":
      ensure => present,
      key => $key_public,
      name => "duplicate of ${user}'s key (${user_email})",
      user => $user,
      type => "ssh-${key_authorized_type}",
      target => "/home/${user}/.ssh/id_${key_private_type}.pub",
      require => File['user-ssh-dir'],
    }
  }

  # if we have a private key
  if ($key_private != '') {
    # allow this machine to ssh to others using ssh-agent-stored key
    class { 'dopki::sshagentadd' :
      user => $user,
      key => $key_private,
      key_passphrase => $key_private_passphrase,
      key_type => $key_private_type,
      require => File['user-ssh-dir'],
    }
  }
}

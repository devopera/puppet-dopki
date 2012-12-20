class dopki (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',
  $user_email = 'admin@example.com',

  # main user's public and private (with passphrase) keys
  $key_public = '',
  $key_private = '',
  $key_private_passphrase = 'admLn**',
  $key_private_type = 'dsa',
  $key_private_name = "id_${key_private_type}",

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
    # also store in /home/<user>/.ssh/<private_key_name>.pub for continuity
    ssh_authorized_key { "extra-id_xsa-${user}":
      ensure => present,
      key => $key_public,
      name => "duplicate of ${user}'s key (${user_email})",
      user => $user,
      type => "ssh-${key_authorized_type}",
      target => "/home/${user}/.ssh/${key_private_name}.pub",
      require => File['user-ssh-dir'],
    }
  }

  # if we have a private key load it, otherwise create one
  if ($key_private == '') {
    # create a new key from scratch
    exec { 'create-key-ssh-id_xsa':
      command => "ssh-keygen -t ${key_private_type} -C 'generated by Devopera for ${user} (${user_email})' -N '${key_private_passphrase}' -f /home/${user}/.ssh/${key_private_name}",
      user    => $user,
      creates => "/home/${user}/.ssh/${key_private_name}",
      require => [User[$user], Package['openssh-client']],
    }
    # common File[] dependency for consistency
    file { 'ssh-id_xsa': 
      path => '/tmp/puppet-dopki-create-key',
      content => '',
      owner => $user,
      require => Exec['ssh-id_xsa-newkey'],
    }
  } else {
    # create a key file from passed var
    file { 'ssh-id_xsa':
      path => "/home/${user}/.ssh/${key_private_name}",
      content => $key_private,
      mode => 0600,
      owner => $user,
      require => [User[$user], Package['openssh-client']],
    }
  }

  # allow this machine to ssh to others using ssh-agent-stored key
  class { 'dopki::sshagentadd' :
    user => $user,
    key_passphrase => $key_private_passphrase,
    key_name => $key_private_name,
    require => [File['user-ssh-dir'], File['ssh-id_xsa']],
  }

}

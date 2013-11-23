define dopki::addkey (

  # defined type arguments
  # ----------------------
  # setup defaults

  $user = 'web',
  $user_email = 'admin@example.com',

  # main user's public and private (with passphrase) keys
  $key_public = '',
  $key_private = '',
  $key_private_passphrase = 'admLn**',
  $key_private_type = 'dsa',
  $key_private_name = undef,

  # load key into agent
  $load_locally = false,

  $notifier_dir = '/etc/puppet/tmp',

  # end of defined type arguments
  # -----------------------------
  # begin defined type

) {

  # derive a name for the private key file, if not defined
  if ($key_private_name == undef) {
    $key_private_name_real = "id_${key_private_type}"
  } else {
    $key_private_name_real = $key_private_name
  }

  # authorised types have slightly different names to key types
  if ($key_private_type == 'dsa') {
    $key_authorized_type = 'dss'
  } else {
    $key_authorized_type = 'rsa'
  }

  # store public key
  if ($key_public != '') {
    # allow other machines to ssh to this one using key
    ssh_authorized_key { "dopki-addkey-${user}-${title}":
      ensure => present,
      key => $key_public,
      name => "key ${title} for ${user_email}",
      user => $user,
      type => "ssh-${key_authorized_type}",
    }
    # also store in /home/<user>/.ssh/<private_key_name>.pub for continuity
    ssh_authorized_key { "dopki-addkey-extra-id_Xsa-${user}-${title}":
      ensure => present,
      key => $key_public,
      name => "duplicate of ${user}'s ${title} key (${user_email}) that is stored in .ssh/authorized_keys",
      user => $user,
      type => "ssh-${key_authorized_type}",
      target => "/home/${user}/.ssh/${key_private_name_real}.pub",
    }
  }

  # store private key, if one passed
  if ($key_private != '') {
    # create a key file from passed var
    file { "ssh-id_Xsa-${title}":
      path => "/home/${user}/.ssh/${key_private_name_real}",
      content => $key_private,
      mode => 0600,
      owner => $user,
      group => $user,
    }
  }

  # @todo This does not work yet as defined type doesn't exist
  if ($load_locally) {
    # allow this machine to ssh to others using ssh-agent-stored key
  }
}

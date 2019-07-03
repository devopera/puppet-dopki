define dopki::addkey (

  # defined type arguments
  # ----------------------
  # setup defaults

  $user = 'web',
  $user_email = 'admin@example.com',
  $user_ssh_access = true,

  # main user's public and private (with passphrase) keys
  $key_public = '',
  $key_private = '',
  $key_private_passphrase = 'admLn**',
  $key_private_type = 'dsa',
  $key_private_name = undef,

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
    if ($user_ssh_access == true) {
      # allow other machines to ssh to this one using key
      ssh_authorized_key { "dopki-addkey-${user}-${title}":
        ensure => present,
        key => $key_public,
        name => "key ${title} for ${user_email}",
        user => $user,
        type => "ssh-${key_authorized_type}",
      }
    }

    # also store in /home/<user>/.ssh/<private_key_name>.pub for continuity
    file { "dopki-addkey-extra-id_Xsa-${user}-${title}":
      path => "/home/${user}/.ssh/${key_private_name_real}.pub",
      ensure => present,
      content => "ssh-${key_authorized_type} ${key_public} duplicate of ${user}'s ${title} key (${user_email}) that is stored in .ssh/authorized_keys",
      mode => '0600',
      owner => $user,
      group => $user,
    }
  }

  # store private key, if one passed
  if ($key_private != '') {
    # create a key file from passed var
    file { "ssh-id_Xsa-${title}":
      path => "/home/${user}/.ssh/${key_private_name_real}",
      content => $key_private,
      mode => '0600',
      owner => $user,
      group => $user,
    }
  }

}

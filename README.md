[devopera](http://devopera.com)-[dopki](http://devopera.com/module/dopki)
=====

Public-key infrastructure for Devopera puppet config.  This module creates, stores and load public-private key pairs to allow access to remote servers, such as GitHub. 

Changelog
---------

2013-09-03

  * Introduced defined type dopki::addkey for adding multiple private and public keys

2013-04-24

  * Private key file in /home/user/.ssh belongs to user (u+g)

2013-02-25

  * Modified to write notifier to parameterized ${notifier_dir}

Usage
-----

Store an existing private key, create an SSH agent (instantiated at first login, then persistent until reboot), load key into agent using auto-load (dev machines only).

    class { 'dopki' :
      user => 'web',
      user_email => 'web@example.com',
      key_public => 'AAAAB3Nza=example=public=key=',
      key_private_type => 'rsa',
      key_private_name => 'id_rsa_keyid',
      key_private => '-----BEGIN RSA PRIVATE KEY-----
        Proc-Type: 4,ENCRYPTED
        DEK-Info: DES-EDE3-CBC,760B99922017D4F9
        ...=example=private=key=...
        -----END RSA PRIVATE KEY-----',
      key_private_passphrase => 'admLn**',
      require => Class['docommon'],
    }

For secure systems take out the auto-load file (created by ```class { 'dopki' }``` above so that the first login requires the user enter the key passphrase.

      class { 'dopki::sshagentcleanup' :
        user => 'web',
        require => Class['dopki::sshagentadd'],
      }


Copyright and License
---------------------

Copyright (C) 2012 Lightenna Ltd

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

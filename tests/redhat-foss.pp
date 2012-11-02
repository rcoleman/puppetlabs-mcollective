# This test can be used to enable MCollective on a machine running
# the open source version of Puppet.  The mcollective::params class
# can be passed further customization, if necessary.

# Setup Puppetlabs Yum repos for mcollective and activemq downloads
yumrepo { 'puppetlabs-products':
  baseurl => 'http://yum.puppetlabs.com/el/$releasever/products/$basearch',
  enabled => 1,
  gpgcheck => 1,
  gpgkey   => 'http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
  before => Class['activemq'],
}

yumrepo { 'puppetlabs-dependencies':
  baseurl => 'http://yum.puppetlabs.com/el/$releasever/dependencies/$basearch',
  enabled => 1,
  gpgcheck => 1,
  gpgkey   => 'http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
  before => Class['activemq'],
}

# This is the puppetlabs-activemq module
class{ 'activemq':
  stomp_port => '61613',
}

class { 'mcollective::params':
  stomp_port => '61613',
  stomp_server => 'stomp_server.yourdomain.net',
  require => Class['activemq'],
}

class { 'mcollective':
  manage_plugins => true,
  require => Class['mcollective::params'],
}

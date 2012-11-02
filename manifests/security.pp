# Class: mcollective::security
#
# This class manages all security components of an MCollective install,
# including necessary certs and java keystores/truststores
#
# Parameters:
#
#  [*version*]       - The version of the MCollective package(s) to
#                        be installed.
#  [*server*]        - Boolean determining whether you would like to
#                        install the server component.
#  [*manage_plugins] - Boolean controlling installation of plugins in module
#                        configuration file.
#  [*client*]        - Boolean determining whether you would like to
#                        install the client component.
#
# Actions:
#
# Requires:
#
#  - Puppetlabs/java_ks module
#
# Sample Usage:
#
#
class mcollective::security(
  $machine_is_a_ca      = $mcollective::params::machine_is_a_ca,
  $machine_is_a_console = $mcollective::params::machine_is_a_console,
  $machine_is_a_master  = $mcollective::params::machine_is_a_master,
  $mc_confdir           = $mcollective::params::mc_confdir,
  $mc_username          = $mcollective::params::mc_username,
  $mc_user_homedir      = $mcollective::params::mc_user_homedir,
  $puppet_ssldir        = $mcollective::params::puppet_ssldir,
  $puppet_ca_server     = $mcollective::params::puppet_ca_server,
  $puppet_user          = $mcollective::params::puppet_user,
  $puppet_group         = $mcollective::params::puppet_group,
  $activemq_user        = $mcollective::params::activemq_user,
  $activemq_group       = $mcollective::params::activemq_group,
  $stomp_port           = $mcollective::params::stomp_port,
  $activemq_confdir     = $mcollective::params::activemq_confdir,
  $mc_enable_stomp_ssl  = $mcollective::params::mc_enable_stomp_ssl
) {

  File {
    owner => '0',
    group => '0',
    mode  => '0644',
  }

  Exec {
    logoutput => on_failure,
    path      => '/opt/puppet/bin:/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
  }
  
  if $machine_is_a_master {
    file { 'credentials':
      path => "${mc_confdir}/credentials",
      mode => '0600',
    }
  
    if $machine_is_a_ca {
      exec { 'mcollective server certificate':
        command => 'puppet cert generate puppet-internal-mcollective-servers',
        creates => "${puppet_ssldir}/certs/puppet-internal-mcollective-servers.pem",
        before  => [
                     File['mcollective-public.pem'],
                     File['mcollective-private.pem'],
                     File['mcollective-cert.pem'],
                   ],
      }
  
      exec { 'mcollective client certificate':
        command => "puppet cert --generate puppet-internal-${mc_username}-mcollective-client",
        creates => "${puppet_ssldir}/certs/puppet-internal-${mc_username}-mcollective-client",
        before  => [
                     File["${mc_username}-public.pem"],
                     File["${mc_user_homedir}/.mcollective.d/${mc_username}-private.pem"],
                     File["${mc_user_homedir}/.mcollective.d/${mc_username}-public.pem"],
                     File["${mc_user_homedir}/.mcollective.d/${mc_username}-cert.pem"]
                   ],
      }
  
      exec { 'puppet dashboard client certificate':
        command => 'puppet cert --generate puppet-internal-puppet-console-mcollective-client',
        creates => "${puppet_ssldir}/certs/puppet-internal-puppet-console-mcollective-client.pem",
        before  => File['puppet-dashboard-public.pem'],
      }
    }
    
    if $mc_enable_stomp_ssl {
      exec { 'broker cert request':
        command => "puppet certificate generate --ca-location remote --mode agent ${::clientcert}.puppet-internal-broker",
        creates => "${puppet_ssldir}/private_keys/${::clientcert}.puppet-internal-broker.pem",
      }
  
      exec { 'broker cert sign':
        command => "curl -S -fail -k -H \"Content-Type: text/pson\" -X PUT -d '{\"desired_state\":\"signed\"}' --cert ${puppet_ssldir}/certs/${::clientcert}.pem --key ${puppet_ssldir}/private_keys/${::clientcert}.pem --cacert ${puppet_ssldir}/certs/ca.pem https://${puppet_ca_server}:8140/production/certificate_status/${::clientcert}.puppet-internal-broker",
        creates => "${puppet_ssldir}/certs/${::clientcert}.puppet-internal-broker.pem",
        require => Exec['broker cert request'],
      }
  
      exec { 'broker cert retrieve':
        command => "curl S -fail -k -X GET -H 'Accept: s' -o ${puppet_ssldir}/certs/${::clientcert}.puppet-internal-broker.pem https://${puppet_ca_server}:8140/production/certificate/${::clientcert}.puppet-internal-broker",
        user    => $puppet_user,
        group   => $puppet_group,
        creates => "${puppet_ssldir}/certs/${::clientcert}.puppet-internal-broker.pem",
        require => Exec['broker cert sign'],
      }
  
      java_ks { "${::clientcert}:keystore":
        ensure      => latest,
        certificate => "${puppet_ssldir}/certs/${::clientcert}.puppet-internal-broker.pem",
        private_key => "${puppet_ssldir}/private_keys/${::clientcert}.puppet-internal-broker.pem",
        target      => "${activemq_confdir}/broker.ks",
        password    => 'puppet',
        require     => Exec['broker cert retrieve'],
        notify      => Service['activemq']
      }
  
      java_ks { 'puppetca:keystore':
        ensure       => latest,
        certificate  => "${puppet_ssldir}/certs/ca.pem",
        target       => "${activemq_confdir}/broker.ks",
        password     => 'puppet',
        trustcacerts => true,
      }
  
      file { "${activemq_confdir}/certs":
        ensure  => directory,
        owner   => $activemq_user,
        group   => $activemq_group,
        mode    => '0750',
        recurse => true,
        purge   => true,
      }
  
      $certs      = broker_bundle("${puppet_ssldir}/ca/signed", '.*puppet-internal-broker.pem$', "${activemq_confdir}/certs")
      $certs_file = $certs[0]
      $certs_jks  = $certs[1]
      $cert_file_defaults = {
        'ensure' => 'file',
        'mode'   => '0640',
        'owner'  => $activemq_user,
        'group'  => $activemq_group
      }
      $java_ks_defaults = {
        'ensure'   => 'latest',
        'target'   => "${activemq_confdir}/broker.ts",
        'password' => 'puppet',
        'before'   => "File[${activemq_confdir}broker.ts]"
      }
  
      create_resources('file', $certs_file, $cert_file_defaults)
      create_resources('java_ks', $certs_jks, $java_ks_defaults)
  
      java_ks { 'puppetca:truststore':
        ensure       => latest,
        certificate  => "${puppet_ssldir}/certs/ca.pem",
        target       => "${activemq_confdir}/broker.ts",
        password     => 'puppet',
        trustcacerts => true,
        before       => File["${activemq_confdir}/broker.ts"],
      }
  
      file { "${activemq_confdir}/broker.ts":
        ensure => file,
        owner  => $activemq_user,
        group  => $activemq_group,
        mode   => '0640',
        notify => Service['activemq'],
      }
    }
  }

  file { "${mc_confdir}/ssl":
    ensure => directory,
    mode   => '0755',
    notify => Service['mcollective'],
  }

  file { 'mcollective-public.pem':
    ensure  => file,
    path    => "${mc_confdir}/ssl/mcollective-public.pem",
    source  => $machine_is_a_ca ? {
      true    => "${puppet_ssldir}/public_keys/puppet-internal-mcollective-servers.pem",
      false   => undef,
    },
    content => $machine_is_a_ca ? {
      true    => undef,
      false   => file("${mc_confdir}/ssl/mcollective-public.pem"),
    },
    notify  => Service['mcollective'],
  }

  file { 'mcollective-private.pem':
    ensure  => file,
    path    => "${mc_confdir}/ssl/mcollective-private.pem",
    source  => $machine_is_a_ca ? {
      true    => "${puppet_ssldir}/private_keys/puppet-internal-mcollective-servers.pem",
      false   => undef,
    },
    content => $machine_is_a_ca ? {
      true    => undef,
      false   => file("${mc_confdir}/ssl/mcollective-private.pem"),
    },
    owner  => '0',
    group  => $puppet_group,
    notify => Service['mcollective'],
  }

  file { 'mcollective-cert.pem':
    ensure  => file,
    path    => "${mc_confdir}/ssl/mcollective-cert.pem",
    source  => $machine_is_a_ca ? {
      true    => "${puppet_ssldir}/certs/puppet-internal-mcollective-servers.pem",
      false   => undef,
    },
    content => $machine_is_a_ca ? {
      true    => undef,
      false   => file("${mc_confdir}/ssl/mcollective-cert.pem"),
    },
    notify => Service['mcollective'],
  }

  file { "${mc_confdir}/ssl/clients":
    ensure => directory
  }

  file { "${mc_username}-public.pem":
    ensure  => file,
    path    => "${mc_confdir}/ssl/clients/${mc_username}-public.pem",
    source  => $machine_is_a_ca ? {
      true    => "${puppet_ssldir},public_keys/puppet-internal-${mc_username}-mcollective-client.pem",
      false   => undef,
    },
    content => $machine_is_a_ca ? {
      true    => undef,
      false   => file("${mc_confdir}/ssl/clients/${mc_username}-public.pem"),
    },
    notify => Service['mcollective'],
  }

  file { 'puppet-dashboard-public.pem':
    ensure  => file,
    path    => "${mc_confdir}/ssl/clients/puppet-dashboard-public.pem",
    source  => $machine_is_a_ca ? {
      true  => "${puppet_ssldir}/public_keys/puppet-internal-puppet-console-mcollective-client.pem",
      false => undef,
    },
    content => $machine_is_a_ca ? {
      true  => undef,
      false => file("${mc_confdir}/ssl/clients/puppet-dashboard-public.pem"),
    },
    notify => Service['mcollective'],
  }

  file { "${mc_confdir}/ssl/clients/mcollective-public.pem":
    ensure  => file,
    source  => "${mc_confdir}/ssl/mcollective-public.pem",
    notify  => Service['mcollective'],
    require => File['mcollective-public.pem'],
  }
}

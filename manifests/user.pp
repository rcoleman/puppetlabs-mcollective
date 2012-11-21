## Issues:
# 1. Need to assume that the machine is a master or a CA for this to work
#
define mcollective::user(
  $home_directory,
  $mc_confdir          = $mcollective::params::mc_confdir,
  $puppet_ssldir       = $mcollective::params::puppet_ssldir,
  $machine_is_a_ca     = $mcollective::params::machine_is_a_ca,
  $machine_is_a_master = $mcollective::params::machine_is_a_master,
  $manage_home         = false,
  # We need to figure out a solution to stomp_pool_real
  # This is needed to access the variable in our template
  $stomp_pool_real     = $mcollective::params::stomp_pool_real
) {

  File {
    owner => $name,
    group => $name,
    mode  => '0644',
  }

  Exec {
    logoutput => on_failure,
    path      => '/opt/puppet/bin:/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
  }

  if $manage_home {
    file { $home_directory:
      ensure => directory,
    }
  }

  if $machine_is_a_master {
    if $machine_is_a_ca {
      # Create the certificates for the user on the CA
      exec { 'mcollective client certificate':
        command => "puppet cert --generate puppet-internal-${name}-mcollective-client",
        creates => "${puppet_ssldir}/certs/puppet-internal-${name}-mcollective-client.pem",
        before  => [
                     File["${name}-public.pem"],
                     File["${home_directory}/.mcollective.d/${name}-private.pem"],
                     File["${home_directory}/.mcollective.d/${name}-public.pem"],
                     File["${home_directory}/.mcollective.d/${name}-cert.pem"]
                   ],
      }
    }

    file { "${name}-public.pem":
      ensure  => file,
      path    => "${mc_confdir}/ssl/clients/${name}-public.pem",
      source  => $machine_is_a_ca ? {
        true    => "${puppet_ssldir}/public_keys/puppet-internal-${name}-mcollective-client.pem",
        false   => undef,
      },
      content => $machine_is_a_ca ? {
        true    => undef,
        false   => file("${mc_confdir}/ssl/clients/${name}-public.pem"),
      },
      notify => Service['mcollective'],
    }  

    file { "${home_directory}/.mcollective.d":
      ensure => directory,
    }

    ## Manage the LOCAL certificates for the MCollective User
    file { "${home_directory}/.mcollective.d/${name}-public.pem":
      ensure  => file,
      source  => $machine_is_a_ca ? {
        true    => "${puppet_ssldir}/public_keys/puppet-internal-${name}-mcollective-client.pem",
        false   => undef,
      },
      content => $machine_is_a_ca ? {
        true    => undef,
        false   => file("${puppet_ssldir}/public_keys/puppet-internal-${name}-mcollective-client.pem"),
      },
      mode    => '0600',
    }

    file { "${home_directory}/.mcollective.d/${name}-private.pem":
      ensure  => file,
      source  => $machine_is_a_ca ? {
        true    => "${puppet_ssldir}/private_keys/puppet-internal-${name}-mcollective-client.pem",
        false   => undef,
      },
      content => $machine_is_a_ca ? {
        true    => undef,
        false   => file("${puppet_ssldir}/private_keys/puppet-internal-${name}-mcollective-client.pem"),
      },
      mode    => '0600',
    }

    file { "${home_directory}/.mcollective.d/${name}-cert.pem":
      ensure  => file,
      source  => $machine_is_a_ca ? {
        true    => "${puppet_ssldir}/certs/puppet-internal-${name}-mcollective-client.pem",
        false   => undef,
      },
      content => $machine_is_a_ca ? {
        true    => undef,
        false   => file("${puppet_ssldir}/certs/puppet-internal-${name}-mcollective-client.pem"),
      },
      mode    => '0600',
    }

    # Create the client configuration file for the user
    file { "${home_directory}/.mcollective":
      ensure  => file,
      content => template('mcollective/client.cfg.erb'),
    }
  }
}

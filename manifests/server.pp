# Class: mcollective::server
#
#   This class installs the MCollective server component for your nodes.
#
# Parameters:
#
#  [*version*]            - The version of the MCollective package(s) to
#                             be installed.
#  [*config*]             - The content of the MCollective client configuration
#                             file.
#  [*config_file*]        - The full path to the MCollective client
#                             configuration file.
#  [*server_config_owner*]  - The owner of the server configuration file.
#  [*server_config_group*]  - The group for the server configuration file.
#  [*mc_service_name*]  - The name of the mcollective service
#  [*mc_service_stop*]  - The command used to stop the mcollective service
#  [*mc_service_start*] - The command used to start the mcollective service
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mcollective::server(
  $version,
  $config,
  $enterprise,
  $manage_packages,
  $service_name,
  $server_config_owner = $mcollective::params::server_config_owner,
  $server_config_group = $mcollective::params::server_config_group,
  $config_file,
  $mc_service_name     = $mcollective::params::mc_service_name,
  $mc_service_stop     = 'UNSET',
  $mc_service_start    = 'UNSET'
) inherits mcollective::params {

  ##################################
  # Manage the MCollective Package #
  ##################################
  if $manage_packages {
    case $osfamily {
      debian: {
        package { 'libstomp-ruby':
          ensure => present,
        }

        package { 'mcollective':
          ensure  => $version,
          require => Package['libstomp-ruby'],
        }
      }
      redhat: {
        package { 'mcollective':
          ensure => $version,
        }
      }
    } 
  }

  ###################################################
  # Manage the MCollective server.cfg Configuration #
  ###################################################
  # NOTE: Need a check to see if we WANT to manage the service
  file { 'server_config':
    path    => $config_file,
    content => $config,
    mode    => '0640',
    owner   => $server_config_owner,
    group   => $server_config_group,
    notify  => Service['mcollective'],
  }

  ##################################
  # Manage the MCollective Service #
  ##################################
  $mc_service_stop_real = $mc_service_stop ? {
    'UNSET' => $mcollective::params::mc_service_stop,
    false   => undef,
    default => $mc_service_stop,
  }
  $mc_service_start_real = $mc_service_start ? {
    'UNSET' => $mcollective::params::mc_service_start,
    false   => undef,
    default => $mc_service_start,
  }

  service { 'mcollective':
    ensure    => running,
    name      => $mc_service_name,
    hasstatus => true,
    start     => $mc_service_start_real,
    stop      => $mc_service_stop_real,
  }
}

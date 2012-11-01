# Class: mcollective
#
# This module manages MCollective. All custom parameter values can be
# changed by modifying the mcollective::params class.
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
#  [*enterprise*]    - Boolean determining whether Puppet Enterprise
#                        configuration defaults should be used.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# The module works with sensible defaults:
#
# node default {
#   include mcollective
# }
#
# These defaults are:
#
# node default {
#   class { 'mcollective':
#     version        => 'present',
#     enterprise     => false,
#     server         => true,
#     client         => false,
#     manage_plugins => true,
#   }
# }
#
class mcollective(
  $version        = $mcollective::params::version,
  $enterprise     = $mcollective::params::enterprise,
  $server         = $mcollective::params::server,
  $client         = $mcollective::params::client,
  $manage_plugins = $mcollective::params::manage_plugins
) inherits mcollective::params
{
  validate_bool($enterprise)
  validate_bool($manage_plugins)
  validate_bool("$server", $v_bool)
  validate_bool("$client", $v_bool)
  validate_re($version, '^[._0-9a-zA-Z:-]+$')

  $server_real               = $server
  $client_real               = $client

  if $version == 'UNSET' {
      $version_real = 'present'
  } else {
      $version_real = $version
  }

  # Add anchor resources for containment
  anchor { 'mcollective::begin': }
  anchor { 'mcollective::end': }

  if $server_real {
    class { 'mcollective::server':
      version         => $version_real,
      manage_packages => $mcollective::params::manage_packages,
      service_name    => $mcollective::params::service_name,
      config          => $mcollective::params::server_config_real,
      config_file     => $mcollective::params::server_config_file_real,
      require         => Anchor['mcollective::begin'],
    }
    # Also manage the plugins
    if $manage_plugins {
      class { 'mcollective::plugins':
        before  => Anchor['mcollective::end'],
        manage_packages => $mcollective::params::manage_packages,
      }
    }
  }

  if $client_real {
    class { 'mcollective::client':
      version         => $version_real,
      config          => $mcollective::params::client_config_real,
      config_file     => $mcollective::params::client_config_file_real,
      manage_packages => $mcollective::params::manage_packages,
      require         => Anchor['mcollective::begin'],
      before          => Anchor['mcollective::end'],
    }
  }
}


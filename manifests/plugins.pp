# Class: mcollective::plugins
#
#   This class deploys the default set of MCollective
#   plugins
#
# Parameters:
#
# Actions:
#
# Requires:
#
#   Class['mcollective']
#   Class['mcollective::service']
#
# Sample Usage:
#
#   This class is intended to be declared in the mcollective class.
#
class mcollective::plugins(
  $plugin_base = $mcollective::params::plugin_base,
  $plugin_subs = $mcollective::params::plugin_subs,
  $manage_plugins,
  $manage_packages
) inherits mcollective::params {

  File {
    owner => '0',
    group => '0',
    mode  => '0644',
  }

  # $plugin_base and $plugin_subs are meant to be arrays.
  file { $plugin_base:
    ensure  => directory,
		require => $manage_packages ? {
		  true  => Package['mcollective'],
		  false => undef,
		},
  }
  file { $plugin_subs:
    ensure => directory,
  }

  if $manage_plugins {
    mcollective::plugins::plugin { 'registration':
      ensure      => present,
      type        => 'agent',
      ddl         => false,
      application => false,
    }
    mcollective::plugins::plugin { 'facter_facts':
      ensure => present,
      type   => 'facts',
    }
    mcollective::plugins::plugin { 'yaml_facts':
      ensure => present,
      type   => 'facts',
    }
    mcollective::plugins::plugin { 'service':
      ensure      => present,
      type        => 'agent',
      ddl         => true,
      application => false,
    }
    mcollective::plugins::plugin { 'package':
      ensure      => present,
      type        => 'agent',
      ddl         => true,
      application => false,
    }
    mcollective::plugins::plugin { 'meta':
      ensure      => present,
      type        => 'registration',
      ddl         => false,
      application => false,
    }
    # Add the NRPE Agent by default
    mcollective::plugins::plugin { 'nrpe':
      ensure      => present,
      type        => 'agent',
      ddl         => true,
      application => true,
    }
  }
}


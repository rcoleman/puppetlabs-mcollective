# Class: mcollective::client
#
#   This class installs the MCollective client component for your nodes.
#
# Parameters:
#
#  [*version*]            - The version of the MCollective package(s) to
#                             be installed.
#  [*config*]             - The content of the MCollective client configuration
#                             file.
#  [*config_file*]        - The full path to the MCollective client
#                             configuration file.
#  [*manage_packages*]    - Whether or not to manage the client packages. Accepts
#                              ensure or absent.
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mcollective::client(
  $version,
  $config,
  $global_client_config,
  $manage_packages,
  $config_file
) inherits mcollective::params { 

  if $manage_packages {
	 	package { 'mcollective-client':
	    ensure => $version,
			before => $global_client_config ? {
			  true =>  File['client_config'],
			  false => undef,
			},
	  }
  }

  if $global_client_config {
	  file { 'client_config':
	    ensure  => present,
      path    => $config_file,
      content => $config,
      mode    => '0600',
      owner   => $client_config_owner,
      group   => $client_config_group,
    }
  }
}

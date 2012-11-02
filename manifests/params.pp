# Class: mcollective::params
#
#   This class provides parameters for all other classes in the mcollective
#   module.  This class should be inherited.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mcollective::params (
	$classesfile          = '/var/lib/puppet/state/classes.txt',
	$client               = false,
	$client_config_file   = '/etc/mcollective/client.cfg',
  $client_config_group  = '0',
  $client_config_owner  = '0',
	$collectives          = 'mcollective',
	$connector            = 'stomp',
	$fact_source          = 'facter',
	$version              = 'UNSET',
	$main_collective      = 'mcollective',
	$manage_packages      = true,
	$manage_plugins       = true,
	$mc_topicprefix       = '/topic/',
	$mc_main_collective   = 'mcollective',
	$mc_collectives       = '',
	$mc_logfile           = '/var/log/mcollective.log',
	$mc_loglevel          = 'log',
	$mc_daemonize         = '1',
	$mc_security_provider = 'psk',
	$mc_security_psk      = 'changemeplease',
  $pkg_state            = 'present',
	$plugin_params        = {},
	$server               = true,
	$server_config_file   = '/etc/mcollective/server.cfg',
	$stomp_user           = 'mcollective',
  $stomp_passwd         = 'marionette',
  $stomp_server         = 'stomp',
  $stomp_port           = '6163',
  $server_config_owner  = '0',
  $server_config_group  = '0',
  $stomp_pool           = 'UNSET',
	$yaml_facter_source   = '/etc/mcollective/facts.yaml'
) {
  validate_re($server_config_file, '^/')
  validate_re($client_config_file, '^/')
  validate_re($mc_security_provider, '^[a-zA-Z0-9_]+$')
  validate_re($mc_security_psk, '^[^ \t]+$')
  validate_re($fact_source, '^facter$|^yaml$')
  validate_re($connector, '^stomp$|^activemq$')
  validate_hash($plugin_params)

  if $stomp_pool == 'UNSET' {
    $stomp_pool_real =
    {
      pool1 =>
      {
        'host1'     => $stomp_server,
        'port1'     => $stomp_port,
        'user1'     => $stomp_user,
        'password1' => $stomp_passwd
      }
    }
  } else {
    $stomp_pool_real = $stomp_pool
  }

  case $osfamily {
    'redhat': {
      $nrpe_dir_real    = '/etc/nrpe.d'
      $mc_service_start = '/sbin/service mcollective start'
      $mc_service_stop  = '/sbin/service mcollective stop'
      $mc_libdir        = '/usr/libexec/mcollective'
    }
    'debian': {
      $mc_libdir        = '/usr/share/mcollective/plugins'
      $mc_service_start = '/etc/init.d/mcollective start'
      $mc_service_stop  = '/etc/init.d/mcollective stop'
    }
    'darwin': {
      $mc_service_name = 'com.puppetlabs.mcollective'
    }
    default: {
      $mc_service_name = 'mcollective'
      $nrpe_dir_real   = '/etc/nagios/nrpe.d'
      $mc_libdir       = '/usr/libexec/mcollective'
    }
  }

  $stomp_pool_size      = size(keys($stomp_pool_real))
	$server_config        = template('mcollective/server.cfg.erb')
	$client_config        = template('mcollective/client.cfg.erb')
  $plugin_base          = "${mc_libdir}/mcollective"
  $plugin_subs          = [
                            "${plugin_base}/agent",
                            "${plugin_base}/application",
                            "${plugin_base}/audit",
                            "${plugin_base}/connector",
                            "${plugin_base}/facts",
                            "${plugin_base}/registration",
                            "${plugin_base}/security",
                            "${plugin_base}/util",
                          ]
}

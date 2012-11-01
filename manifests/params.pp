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
class mcollective::params {
  $version              = 'UNSET'
  $enterprise           = false
  $manage_packages      = true
  $manage_plugins       = false
  $server               = true
  $server_config        = 'UNSET'
  $server_config_file   = '/etc/mcollective/server.cfg'
  $client               = false
  $client_config        = 'UNSET'
  $client_config_file   = '/etc/mcollective/client.cfg'
  $main_collective      = 'mcollective'
  $collectives          = 'mcollective'
  $connector            = 'stomp'
  $classesfile          = '/var/lib/puppet/state/classes.txt'
  $stomp_pool           = 'UNSET'
  $mc_topicprefix       = '/topic/'
  $mc_main_collective   = 'mcollective'
  $mc_collectives       = ''
  $mc_logfile           = '/var/log/mcollective.log'
  $mc_loglevel          = 'log'
  $mc_daemonize         = '1'
  $mc_security_provider = 'psk'
  $mc_security_psk      = 'changemeplease'
  $fact_source          = 'facter'
  $yaml_facter_source   = '/etc/mcollective/facts.yaml'
  $plugin_params        = {}

  case $osfamily {
    'redhat': {
      $nrpe_dir_real = '/etc/nrpe.d'
      $mc_service_start = '/sbin/service mcollective start',
      $mc_service_stop  = '/sbin/service mcollective stop',
    }
    'debian': {
      $mc_libdir = '/usr/share/mcollective/plugins'
      $mc_service_start = '/etc/init.d/mcollective start', 
      $mc_service_stop  = '/etc/init.d/mcollective stop',
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

  $plugin_base = "${mc_libdir}/mcollective"

  $plugin_subs = [
    "${plugin_base}/agent",
    "${plugin_base}/application",
    "${plugin_base}/audit",
    "${plugin_base}/connector",
    "${plugin_base}/facts",
    "${plugin_base}/registration",
    "${plugin_base}/security",
    "${plugin_base}/util",
  ]

  $client_config_owner  = '0'
  $client_config_group  = '0'
  $server_config_owner  = '0'
  $server_config_group  = '0'

  $stomp_user    = 'mcollective'
  $stomp_passwd  = 'marionette'
  $stomp_server  = 'stomp'
  $stomp_port    = '6163'

  $pkg_state = 'present'

}

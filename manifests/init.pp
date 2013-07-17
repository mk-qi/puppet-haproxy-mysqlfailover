class haproxy::setup::mysql {

   file {["/opt/scripts/mysqlhealth/"]:
        ensure => directory,
         owner   => root,
        group   => root,
        mode    => 0644,

   }

   file {
        "/etc/xinetd.d/mysqlchk":
        ensure  => present,
        mode    => 0644,
        owner   => root,
        group   => root,
        content => template("haproxy/mysqlchk.erb"),
    }
   file {
        "/opt/scripts/mysqlhealth/mysqlchk_status.sh":
        ensure  => present,
        mode    => 0755,
        owner   => root,
        group   => root,
        content => template("haproxy/mysqlchk_status.erb"),
    }
    file {
        "/etc/services":
        ensure  => present,
        mode    => 0755,
        owner   => root,
        group   => root,
        content => template("haproxy/services.erb"),
    }
    file {
        "/etc/logrotate.d/chkmysql":
        ensure  => present,
        mode    => 0755,
        owner   => root,
        group   => root,
        content => template("haproxy/chkmysql.erb"),
    }
    
    package { 'xinetd':
        ensure => 'present'
    }
    service { 'xinetd':
        enable => true,
        ensure => running,
        hasrestart => true,
        hasstatus => true,
        subscribe    => File['/etc/xinetd.d/mysqlchk'],
        restart => "/etc/init.d/xinetd restart",
        status => "/etc/init.d/xinetd status",
    }
}
class haproxy::setup::haproxy{

    $packages = ['haproxy','keepalived']
     package { $packages:
            ensure => 'present'
     }
        
     file {
        "/etc/keepalived/keepalived.conf":
        ensure  => present,
        mode    => 0755,
        owner   => root,
        group   => root,
        content => template("haproxy/keepalived.conf.erb"),
     }
    
     file {
        "/etc/haproxy/haproxy.cfg":
        ensure  => present,
        mode    => 0755,
        owner   => root,
        group   => root,
        content => template("haproxy/haproxy.cfg.erb"),
    } 

    service { 'keepalived':
        enable => true,
        ensure => running,
        hasrestart => true,
        hasstatus => true,
        subscribe    => File['/etc/keepalived/keepalived.conf'],
        restart => "/etc/init.d/keepalived restart",
        status => "/etc/init.d/keepalived status",
    }
    
    service { 'haproxy':
        enable => true,
        ensure => running,
        hasrestart => true,
        hasstatus => true,
        subscribe    => File['/etc/haproxy/haproxy.cfg'],
        restart => "/etc/init.d/haproxy restart",
        status => "/etc/init.d/haproxy status",
    }
    file_line { 'haproxybindsharedip':
        path => '/etc/sysctl.conf',
        line => 'net.ipv4.ip_nonlocal_bind = 1',
    }

} 

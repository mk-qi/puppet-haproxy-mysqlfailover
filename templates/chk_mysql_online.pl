#!/usr/bin/perl -w
# 
use DBI;
use strict;
use IO::Socket::INET;

# GLOBLE CONFIG VARIABLES
my %status = ( 'OK' => 0 );
my $host = get_local_ip_address();
my $port = "3306";
my $timeout = 2; #2s
# the master and slave are the same
my $username = "test";
my $password = "test";

# get master ip from slave host return
my $master_host = "";
my $master_port = "";
my $report->{''} = "";

# stor the server status that determain  
# return error code
my $serstatus->{mysqlrun} = "";
   $serstatus->{slaverun} = "";
   $serstatus->{masterun} = "";
# as you see, it stor the error msg that 
# from dbi:errmgs return
my $errmsg->{mysql} = "";
   $errmsg->{mastr} = "";

# This idea was stolen from Net::Address::IP::Local::connected_to()
# refe 
sub get_local_ip_address {
    my $socket = IO::Socket::INET->new(
        Proto       => 'udp',
        PeerAddr    => '198.41.0.4', # a.root-servers.net
        PeerPort    => '53', # DNS
    );
    # A side-effect of making a socket connection is that our IP address
    # is available from the 'sockhost' method
    my $local_ip_address = $socket->sockhost;
    return $local_ip_address;
}



# GET LOCAL MYSQL STATUS
eval {
  # Connect to the database.
  my $dbh = DBI->connect("DBI:mysql:database=test;host=$host;post=$port;mysql_connect_timeout=$timeout","$username", "$password",
                        {'RaiseError' => 1, 'PrintError' => 0});
  my $sth = $dbh->prepare("show slave status") ; 
  $sth->execute();
  my $status = $sth->fetchrow_hashref();

  #foreach( keys %$status ) {
 	     #print "$_ = $status->{$_} \n";
  #};

   # get master host's ip and port
   $master_host = $status->{Master_Host};
   $master_port = $status->{Master_Port};
   # get local mysql status 
   $serstatus->{mysqlrun} = "Yes" if $status->{Master_Host};
   # Set slave thread as up  
   $serstatus->{slaverun} = "Yes" if $status->{Slave_IO_Running} eq "Yes" and $status->{Slave_SQL_Running} eq "Yes" and $status->{Seconds_Behind_Master} eq "0";
   # Set slave thread as down if Slave_IO_Running value is not Yes
   $serstatus->{slaverun} = "No"  if $status->{Slave_IO_Running} ne "Yes";
  
  
  # do {} until (!$sth->more_results);
  $sth->finish();
  # Disconnect from the database.
  $dbh->disconnect();
};
if ($@) {
  $serstatus->{mysqlrun} = 'No';
  $errmsg->{mysql} = $DBI::errstr;
}

eval{
  # get slave status (should only be 1 result row)  
  my $dbm = DBI->connect("DBI:mysql:database=test;host=$master_host;port=$master_port;mysql_connect_timeout=$timeout","$username", "$password",
                        {'RaiseError' => 1, 'PrintError' => 0});
  my $mth = $dbm->prepare("show master status") ; 
  $mth->execute();
  my $status = $mth->fetchrow_hashref();
  #foreach( keys %$status ) {
 	     #print "$_ = $status->{$_} \n";
  #};
   
   if ($status->{Position}){
       $serstatus->{masterun} = "Yes"
   }else{
       $serstatus->{masterun} = "No"
   }
      
   $mth->finish;
   $dbm->disconnect;                         
};
if ($@) {
  $serstatus->{masterun} = 'No';
  $errmsg->{mastr} = $DBI::errstr;
}
#print "mysqlrun:" . $serstatus->{mysqlrun} . "\n"
#print  "slaverun:" . $serstatus->{slaverun} . "\n";
#print  "masterun:" . $serstatus->{masterun} . "\n";

if($serstatus->{mysqlrun} eq 'Yes' and $serstatus->{slaverun} eq 'Yes' and $serstatus->{masterun} eq 'Yes') {
        print  "HTTP/1.1 200 OK\r\n" ;
        print  "Content-Type: Content-Type: text/plain\r\n";
        print  "1\r\n" ;
        print  "mysqlrun:" . $serstatus->{mysqlrun} . "\n";
        print  "slaverun:" . $serstatus->{slaverun} . "\n";
        print  "masterun:" . $serstatus->{masterun} . "\n";
        print  "\r\n";
}elsif($serstatus->{mysqlrun} eq 'Yes' and $serstatus->{slaverun} eq 'No' and $serstatus->{masterun} eq 'No') {
        print  "HTTP/1.1 200 ERROR\r\n";
        print  "Content-Type: Content-Type: text/plain\r\n";
        print  "2\r\n" ;
        print  "mysqlrun:" . $serstatus->{mysqlrun} . "\n";
        print  "slaverun:" . $serstatus->{slaverun} . "\n";
        print  "masterun:" . $serstatus->{masterun} . "\n";
}elsif($serstatus->{mysqlrun} eq 'Yes' and $serstatus->{slaverun} eq 'No' and $serstatus->{masterun} eq 'Yes') {
     	  print  "HTTP/1.1 503 Service Unavailable\r\n";
        print  "Content-Type: Content-Type: text/plain\r\n";
        print  "\r\n" ;
        print  "3\r\n" ;
        print  "mysqlrun:" . $serstatus->{mysqlrun} . "\n";
        print  "slaverun:" . $serstatus->{slaverun} . "\n";
        print  "masterun:" . $serstatus->{masterun} . "\n";
}elsif($serstatus->{mysqlrun} eq 'No') {
	      print  "HTTP/1.1 503 Service Unavailable\r\n";
        print  "Content-Type: Content-Type: text/plain\r\n";
        print  "\r\n";
        print  "4\r\n" ;
        print  "mysqlrun:" . $serstatus->{mysqlrun} . "\n";
        print  "slaverun:" . $serstatus->{slaverun} . "\n";
        print  "masterun:" . $serstatus->{masterun} . "\n";
        print  "$errmsg->{mysql} \n" ;
        print  "$errmsg->{mastr}";
}else {
	    print  "HTTP/1.1 503 Service Unavailable\r\n";
        print  "Content-Type: Content-Type: text/plain\r\n";
        print  "\r\n";
        print  "5\r\n" ;
        #print  "Connection Error: $msterr\n";
        print  "\r\n";

};

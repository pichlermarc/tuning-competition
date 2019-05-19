
use DBI;
my $db        = "benchmark";  # Put name of your database schema here
my $port      = 3306; # Port of your MYSQL Instance
my $host      = $opt{h} || "127.0.0.1"; # IP of your MYSQL Instance
my $user      = "root"; # MYSQL User
my $pass      = "dbt2014"; # MYSQL Password
my $dsn       = "DBI:mysql:$db:$host;port=$port"; # Do not edit this one!
my $ISOLATIONLEVEL = 'SERIALIZABLE'; # READ UNCOMMITTED | READ COMMITTED | REPEATABLE READ | SERIALIZABLE
my $locktimeout = 300; # Timeout for getting Innodb locks

sub getDBConfig{
	return($db,$port,$host,$user,$pass,$dsn,$ISOLATIONLEVEL,$locktimeout);
}

# Next Steps;
# Execute createDB.pl in order to generate your database
# Execute clientsim.pl in order to generate some traffic...
1;
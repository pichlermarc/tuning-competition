#!/usr/bin/perl -w
use lib '.';
use MyBench;
use Getopt::Std;
use Time::HiRes qw(gettimeofday tv_interval);
my %opt;
Getopt::Std::getopt('n:r:h:', \%opt);

my $loglang = "de"; # Use for nice output for German excel
my $duration  = $opt{r} || 300;  # Execute test for 30 seconds or use other duration with commandline option -r

my $started = [gettimeofday];
my $filename = "logs/result-$duration-".time().".csv";
open(my $LOG, ">$filename");
flock $LOG, 2;
print $LOG "ID;NUMRUNS;MIN;AVG;MAX;ERRORS\n";
close $LOG; 

my @lines;
open(my $file, 'data/queries.txt');
while (<$file>) {
	push @lines, $_ unless $_ =~ /^#/;
}
close $file;
	
my @emails;
open($file, 'data/emails.txt');
while (<$file>) {
	my $mail = $_;
	chomp $mail;
	push @emails, $mail;
}
close $file;

my @groups;
open($file, 'data/groups.txt');
while (<$file>) {
	my $group = $_;
	chomp $group;
	push @groups, $group;
}
close $file;


my @vornamen;
open($file, 'data/vornamen.txt');
while (<$file>) {
	my @vorname = split(/\t/,$_);
	push @vornamen, $vorname[0];
}
close $file;
	
my @nachnamen;
open($file, 'data/nachnamen.txt');
while (<$file>) {
	my $nachname = $_;
	chomp $nachname;
	push @nachnamen, $nachname;
}
close $file;
	
my $num_kids  = $opt{n} || $#lines+1;

my $callback = sub
{
	my $id  = shift;
	my $errors = 0;
	## wait for the parent to HUP me
    local $SIG{HUP} = sub { };
	
	require("conf/dbconf.pl");
	my ($db,$port,$host,$user,$pass,$dsn,$ISOLATIONLEVEL,$locktimeout) = getDBConfig();
	my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 0 });
    $dbh->{AutoCommit} = 0; 
    $dbh->do("SET SESSION TRANSACTION ISOLATION LEVEL $ISOLATIONLEVEL");
    $dbh->do("SET INNODB_LOCK_WAIT_TIMEOUT = ".$locktimeout);
 
	$id2 = $id+1;
	my $cnt = 0;
    my @times = ();
	
	while (tv_interval($started, [gettimeofday])< $duration)
		{
		$cnt++;
		my ($timer,$query) = split(/\|/,$lines[$id]);
		my @queries = split(/;/,$query); 
		my $URL = 'http://www.somephoto/ID'.$cnt.'-'.rand(10000);
		my $t0 = [gettimeofday];
		my $waits = 0;
		foreach my $q (@queries) {
			if(tv_interval($started, [gettimeofday])< $duration) {
			if ($q =~ /\[\[SLEEP\]\]/) {
					my $sleeptime = int(rand(5));
					print "\n".'[ID '.$id2.'] Going for a coffee for '.$sleeptime." seconds\n";
					$waits +=$sleeptime;
					sleep($sleeptime);
				}
			elsif ($q =~ /\[\[COMMIT\]\]/) {
					$dbh->commit();
				}
			elsif ($q ne "") {
				my $myemail1 = @emails[int(rand($#emails))];
				my $myemail2 = @emails[int(rand($#emails))];
				my $myemail3 = @emails[int(rand($#emails))];
				my $group = @groups[int(rand($#groups))];
				my $LASTNAME1TO2 = substr(@nachnamen[int(rand($#nachnamen))],2);
				
				$q =~ s/\[\[LASTNAME1TO2\]\]/$LASTNAME1TO2/g;
				$q =~ s/\[\[URL\]\]/$URL/g;
				$q =~ s/\[\[EMAIL1\]\]/$myemail1/g;
				$q =~ s/\[\[EMAIL2\]\]/$myemail2/g;
				$q =~ s/\[\[EMAIL3\]\]/$myemail3/g;
				$q =~ s/\[\[GROUP\]\]/$group/g;
				
				while ($q =~ /\[\[EMAIL\]\]/) { 
					my $myemail = @emails[int(rand($#emails))];
					$q =~ s/\[\[EMAIL\]\]/$myemail/;
					}

				while ($q =~ /\[\[FIRSTNAME\]\]/) { 
					my $myemail = @vornamen[int(rand($#vornamen))];
					$q =~ s/\[\[FIRSTNAME\]\]/$myemail/;
					}
				while ($q =~ /\[\[LASTNAME\]\]/) { 
					my $myemail = @nachnamen[int(rand($#nachnamen))];
					$q =~ s/\[\[LASTNAME\]\]/$myemail/;
					}
				while ($q =~ /\[\[YEAR\]\]/) { 
					my $year = int(rand(14)+2000);
					$q =~ s/\[\[YEAR\]\]/$year/;
					}
								
				if ($q =~ /select / and $q !~ /create/ ) {
					my $sth = $dbh->prepare($q);
					if ($sth->execute()) {
						while (my @dump = $sth->fetchrow_array())   { 
						if ($sth->err) {
							logError("[ID $id2] ".$sth->err . " error msg: " . $sth->errstr,$filename);
							}
							#print $dump[0]."\n";
							}
					}
					elsif ($sth->err) {
						logError("[ID $id2] ".$sth->err . " error msg: " . $sth->errstr,$filename);
					}
					$sth->finish();
					}
				elsif ($q =~/update|delete|insert/) {
					$dbh->do($q);
					if ( $dbh->err )
						{
						logError("[ID $id2] ".$dbh->err . " error msg: " . $dbh->errstr,$filename);
						$errors++;
						}
					}
				}
			}
			}
		   my $t1 = tv_interval($t0, [gettimeofday])- $waits ;
		   print '[ID '.$id2.'] Time for Query: '.$t1." seconds \n";
		   push @times, $t1;
		   
		   if (tv_interval($started, [gettimeofday])< $duration) {
				my $sleeptime = int(rand($timer+1));
				print '[ID '.$id2.'] Sleeping '.$sleeptime." seconds\n";
				sleep($sleeptime);
			}
	}

	print "[ID $id2]\t Quitting. Runs: $cnt\t Min: ".sprintf("%.4f", min(@times)).'s Avg: '.sprintf("%.4f", avg(@times)).'s Max: '.sprintf("%.4f", max(@times))."s\n" unless !@times;
    
	if (@times) {
		open(my $LOG, ">>$filename");
		flock $LOG, 2;
		my $logline = $id2.';'.$cnt.';'.sprintf("%.4f", min(@times)).';'.sprintf("%.4f", avg(@times)).';'.sprintf("%.4f", max(@times)).';'.$errors."\n";
			if ($loglang eq "de") {
				$logline =~ s/\./,/g;
				}
		print $LOG $logline;
		close $LOG;
	}
	## cleanup
    $dbh->disconnect();
    my @r = ($id, scalar(@times), 0, max(@times), avg(@times), tot(@times));
    return @r;
};

my @results = MyBench::fork_and_work($num_kids, $callback);
MyBench::compute_results('Overall', @results);


sub logError{
my $message = shift;
my $filename = shift;
open(my $LOG, ">>$filename.error.txt");
flock $LOG, 2;
print $LOG $message."\n";
close $LOG;
}

exit;

__END__

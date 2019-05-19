#!/usr/bin/perl -w

# Call me with: perl createDB.pl {default|small|tiny}

require("./conf/dbconf.pl");
my $config = 'default';

my %config;
$config{'default'}{'photos'} = 1000000;
$config{'default'}{'nachrichten'} = 500000;
$config{'default'}{'personmultiplier'} = 5;
$config{'default'}{'istabgebildet'} = 10;
$config{'default'}{'istingruppe'} = 10;
$config{'default'}{'friendratio'} = 5;

$config{'small'}{'photos'} = 500000;
$config{'small'}{'nachrichten'} = 500000;
$config{'small'}{'personmultiplier'} = 2;
$config{'small'}{'istabgebildet'} = 10;
$config{'small'}{'istingruppe'} = 10;
$config{'small'}{'friendratio'} = 5;

$config{'tiny'}{'photos'} = 100000;
$config{'tiny'}{'nachrichten'} = 50000;
$config{'tiny'}{'personmultiplier'} = 1;
$config{'tiny'}{'istabgebildet'} = 5;
$config{'tiny'}{'istingruppe'} = 10;
$config{'tiny'}{'friendratio'} = 5;

my $inconfig = shift;
$config = $inconfig unless !$config{$inconfig}{'photos'};
print "Using $config Configuration\n";

my ($db,$port,$host,$user,$pass,$dsn) = getDBConfig();
my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 0 });
$dbh->{AutoCommit} = 0; 
my $startedTime = time();

open(my $LOG, ">>logs/createDbLog.txt");
flock $LOG, 2;
print $LOG "\n\n----------------- Started with $config configuration-----------------------\n";


print $LOG "Creating Databse started\n ";
print $LOG localtime(time());
print $LOG "\n";
my $file;
open($file,"data/vornamen.txt");
my @vornamen = <$file>;
close $file;

my @groups;
open($file, 'data/groups.txt');
while (<$file>) {
	my $group = $_;
	chomp $group;
	push @groups, $group;
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

my @emails = ('gmail.com','yahoo.com','gmx.net','aon.at','sms.at','aau.at','uni-klu.ac.at','web.de','live.at','outlook.com','edu.auu.at','me.com');
my @userkeys;

my $i = 0;

print "Deleting old Tables\n";
$dbh->do("drop table IF EXISTS nachricht;");
$dbh->do("drop table IF EXISTS hatfreund;");
$dbh->do("drop table IF EXISTS istingruppe;");
$dbh->do("drop table IF EXISTS istabgebildet;");
$dbh->do("drop table IF EXISTS gruppe;");
$dbh->do("drop table IF EXISTS photo;");
$dbh->do("drop table IF EXISTS person;");
$dbh->do("drop table IF EXISTS freundecount;");

$dbh->commit();

print "Creating new Tables\n";
$dbh->do("create table person(
email VARCHAR(60) PRIMARY KEY NOT NULL,
vorname VARCHAR(255),
nachname VARCHAR(255),
geburtsdatum DATE,
geschlecht text
);");

$dbh->do("create table gruppe (
name VARCHAR(30) PRIMARY KEY NOT NULL,
beschreibung VARCHAR(255),
emailowner VARCHAR(60) references person(email)
);");

$dbh->do("create table photo(
URL VARCHAR(255) PRIMARY KEY NOT NULL,
titel VARCHAR(60),
beschreibung VARCHAR(1000),
personemail tinytext references person(email)
);");



$dbh->do("create table nachricht(
id INTEGER PRIMARY KEY  NOT NULL auto_increment,
vonemail VARCHAR(60) references person(email),
anemail VARCHAR(60) references person(email),
betreff text,
datum date,
messagetext VARCHAR(10000)
);");

$dbh->do("create table hatfreund(
email VARCHAR(60) references person(email),
emailfreund VARCHAR(60) references person(email),
	CONSTRAINT hatfreundKEY primary key(email,emailfreund)
);");

$dbh->do("create table istingruppe(
gruppename VARCHAR(30) references gruppe(name),
email VARCHAR(60) references person(email),
	CONSTRAINT istingruppeKEY primary key(gruppename,email)
);");

$dbh->do("create table istabgebildet(
photourl VARCHAR(255) references photo(URL),
personemail VARCHAR(60) references person(email),
CONSTRAINT istabgebildetKEY primary key(photourl,personemail)
);");

$dbh->commit();
# Create users;

print "Adding Persons\n";
my %keys;

open(my $emails, ">data/emails.txt");

foreach my $nachname (@nachnamen) {
	chomp $nachname;
	my $personmultiplier = rand($config{$config}{'personmultiplier'});
	for (my $c = 0; $c<=$personmultiplier; $c++) {
		foreach my $vorname1 (@vornamen) {
			$i++;
			($vorname,$geschl) = split(/\t/,$vorname1);
			chomp $geschl;
			my $mail = "\@$emails[$i%$#emails]";
			if ($i%2 == 0) { $mail = "$vorname.$nachname$mail";}
			else { $mail = substr($vorname,0,1).".$nachname$mail";}                                                               

			$mail =~ s/�/ae/;
			$mail =~ s/�/oe/;
			$mail =~ s/�/ue/;
			$mail =~ s/�/Ae/;
			$mail =~ s/�/Oe/;
			$mail =~ s/�/Ue/;
			$mail =~ s/�/ss/;
			
			if ($keys{$mail}) {
				$keys{$mail}++;
				$mail = $keys{$mail}.$mail;
			}	

			my $gebjahr = 2014-18-$i%10;
			my $gebmonat = $i%12+1;
			my $gebtag = $i%28+1;
			$gebtag = "0$gebtag" if $gebtag < 10;
			$gebmonat = "0$gebmonat" if $gebmonat < 10;
			$gebdat = "$gebjahr-$gebmonat-$gebtag";
			
			$dbh->do("insert into person (email,vorname,nachname,geburtsdatum,geschlecht) values ('$mail','$vorname','$nachname','$gebdat','$geschl');");
			print $emails $mail."\n";
			$keys{$mail}++;
			push(@userkeys,$mail);
		}
	}
}
$dbh->commit();
close $emails;
print "Adding Groups\n";

# Create Groups
my %groupowners;

foreach my $group (@groups) {
	my $owner = $userkeys[int(rand($#userkeys))];
    $groupowners{$group} = $owner;
	$dbh->do("insert into gruppe (name,beschreibung,emailowner) values ('$group','What should I say: just $group!','$owner');");
  }
$dbh->commit();
# Create photos:
print "Adding $config{$config}{'photos'} Photos\n";
my @photos;
for(my $i=0; $i < $config{$config}{'photos'}; $i++) {
	my $personemail = $userkeys[int(rand($#userkeys))];
	my $url = "http://www.flickr.com/myphoto/$personemail";
	$url =~ s/\@.*/\/$i.jpg/g;
	my $titel = "Photo Number $i";
	my $beschreibung = "This is a very nice picture taken by $personemail";
	my $length = rand(900);
		for (my $k=0; $k<$length; $k = $k+100) {
			$beschreibung .= 'ABCDE FGHI JKLMK 1789 ABCDE FGHI JKLMK 1789 ABCDE FGHI JKLMK 1789 ABCDE FGHI JKLMK 1789 ABCDE FGHI ';
		}
		
	$dbh->do("insert into photo (URL,titel, beschreibung,personemail) values ('$url','$titel','$beschreibung','$personemail');");
	push(@photos,$url);
}
$dbh->commit();
# create messages

print "Adding $config{$config}{'nachrichten'} Messages\n";
my @subjects = ('RE','Good morning','Did you know?','Happy Birthday!','FWD','Good luck!','Bad news','Goos news');
for(my $i=0; $i <$config{$config}{'nachrichten'}; $i++) {
	my $mailfrom = $userkeys[int(rand($#userkeys))];
    my $mailto = $userkeys[int(rand($#userkeys))];

    if ($mailfrom ne $mailto) {
    	my $betreff = $subjects[rand(1000)%$#subjects];
        my $monat = $i%12+1;
		my $tag = $i%28+1;
		my $year = int(rand(14)+2000);
		$tag = "0$tag" if $tag < 10;
		$monat = "0$monat" if $monat < 10;
    	my $datum = "$year-$monat-$tag";
    	my $messagetext = "some message about $betreff";
		
		my $length = rand(5000);
		for (my $k=0; $k<$length; $k = $k+100) {
			$messagetext .= 'ABCDE FGHI JKLMK 1789 ABCDE FGHI JKLMK 1789 ABCDE FGHI JKLMK 1789 ABCDE FGHI JKLMK 1789 ABCDE FGHI ';
		}
		$dbh->do("insert into nachricht (vonemail,anemail,betreff,datum,messagetext) values ('$mailfrom','$mailto','$betreff','$datum','$messagetext');");
        }
    }


$dbh->commit();
# assign friends
print "Assigning Friends\n";
my %addedfriend;
foreach my $person (@userkeys) {
	foreach my $friend (@userkeys) {
		if ($friend ne $person and !$addedfriend{"$friend-$person"} and rand(10000) < $config{$config}{'friendratio'}) {
			$dbh->do("insert into hatfreund (email,emailfreund) values ('$friend','$person');");
			$dbh->do("insert into hatfreund (email,emailfreund) values ('$person','$friend');");
			$addedfriend{"$friend-$person"} = 1;
			$addedfriend{"$person-$friend"} = 1;
		}
   }
}
$dbh->commit();
# 
print "Assigning Groups\n";
foreach my $person (@userkeys) {
	my %istingroup;
    if (rand($config{$config}{'istingruppe'}) > 3) {

        for (my $i=0; $i< rand($config{$config}{'istingruppe'}); $i++) {
	        my $groupname = $groups[int(rand($#groups))];
	        if ($groupowners{$groupname} ne $person and !$istingroup{$groupname}{$person}) {
	                $dbh->do("insert into istingruppe (gruppename,email) values ('$groupname','$person');");
	                $istingroup{$groupname}{$person} = 1;
	            }
	            }
	        }
}
$dbh->commit();
# Assign istabgebildet

print "Assigning up to $config{$config}{'istabgebildet'} Persons for each Photo\n";
my %abgebildet;
foreach my $photo (@photos) {

 for (my $i=0; $i< rand($config{$config}{'istabgebildet'}); $i++) {
 	my $person = $userkeys[int(rand($#userkeys))];

 if (!$abgebildet{$photo}{$person}) {
    $dbh->do("insert into istabgebildet (photourl,personemail) values ('$photo','$person');");
 	$abgebildet{$photo}{$person} = 1;
 	}
}
}
$dbh->commit();

# Adding a "materialized view freundecount";

$dbh->do("create table freundecount as (select p.email, p.vorname, p.nachname, count(*) as anzahl from person p, hatfreund h where p.email = h.email group by p.vorname, p.nachname);");
$dbh->commit();

my $finishedTime = time();
my $duration = $finishedTime - $startedTime;

print $LOG "Creating Databse finished\n";
print $LOG localtime(time());
print $LOG "\nDuration in seconds: ".$duration;
close $LOG;


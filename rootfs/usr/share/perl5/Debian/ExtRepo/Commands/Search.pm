package Debian::ExtRepo::Commands::Search;

use v5.28;
use warnings;

use Debian::ExtRepo::Data qw/fetch_repodata/;
use YAML::XS qw/Dump/;

sub run {
	my $config = shift;
	my $mirror = shift;
	my $searchkey = shift;
	my $extrepos = fetch_repodata($config);
	my $found = 0;

	foreach my $repo(keys %$extrepos) {
		if($repo =~ /$searchkey/ || $extrepos->{$repo}{description} =~ /$searchkey/ || $extrepos->{$repo}{source}{URIs} =~ /$searchkey/) {
			print "Found $repo:\n";
			print Dump($extrepos->{$repo});
			print "\n\n";
			$found = 1;
		}
	}
	if(!$found) {
		print "No matches found for $searchkey\n";
		exit 1;
	}
}

1;

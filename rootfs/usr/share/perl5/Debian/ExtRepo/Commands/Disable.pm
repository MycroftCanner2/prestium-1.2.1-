package Debian::ExtRepo::Commands::Disable;

use Dpkg::Control::HashCore;

sub run {
	my $config = shift;
	my $mirror = shift;
	my $repo = shift;
	
	my $aptfile = "/etc/apt/sources.list.d/extrepo_$repo.sources";

	if (! -f $aptfile) {
		print "Configuration for $repo does not exist, so not disabled.\n";
		return;
	}
	my $conf = Dpkg::Control::HashCore->new;
	$conf->load($aptfile);
	$conf->{Enabled} = "no";
	$conf->save($aptfile);
}

1;

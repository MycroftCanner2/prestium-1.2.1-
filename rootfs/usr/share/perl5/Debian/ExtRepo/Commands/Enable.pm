package Debian::ExtRepo::Commands::Enable;

use v5.28;
use warnings;

use Debian::ExtRepo::Data qw/fetch_repodata/;
use Dpkg::Control::HashCore;
use LWP::UserAgent;
use Crypt::Digest::SHA256 qw/sha256_hex/;
use autodie qw/system/;

sub run {
	my $config = shift;
	my $mirror = shift;
	my $update_mode = shift;
	my $reponame = shift;
	my $conf = Dpkg::Control::HashCore->new;

	if(!length($reponame)) {
		foreach my $file(glob("/etc/apt/sources.list.d/extrepo_*.sources")) {
			next unless $file =~ /extrepo_(.*)\.sources/;
			run($config, $mirror, $update_mode, $1);
		}
		return;
	}

	die "Need to be root to modify external repository configuration!\n" unless($< == 0);

	umask 0022;

	my $extrepos = fetch_repodata($config);

	die "Repository $reponame does not exist!" unless exists($extrepos->{$reponame});
	my $repo = $extrepos->{$reponame};

	if(exists($config->{tor}) && defined($config->{tor}) && $config->{tor} ne "off") {
		if($config->{tor} eq "onion") {
			if(!exists($repo->{"onion-URIs"})) {
				die ".onion URL requested, but the repository $reponame does not have a .onion URL configured.\n";
			}
			$repo->{source}{URIs} = "tor+" . $repo->{"onion-URIs"};
		} elsif($config->{tor} eq "tunnel") {
			$repo->{source}{URIs} = "tor+" . $repo->{source}{URIs};
		} elsif($config->{tor} eq "auto") {
			$repo->{source}{URIs} = "tor+" . (exists($repo->{"onion-URIs"}) ? $repo->{"onion-URIs"} : $repo->{source}{URIs});
		} elsif($config->{tor} eq "if-onion") {
			$repo->{source}{URIs} = exists($repo->{"onion-URIs"}) ? ("tor+" . $repo->{"onion-URIs"}) : $repo->{source}{URIs};
		} else {
			die "invalid value for tor configuration: found " . $config->{tor} . ", expecting one of onion, tunnel, auto, if-onion, or off";
		}
	}

	my $aptfile = "/etc/apt/sources.list.d/extrepo_$reponame.sources";

	if(!$update_mode && -f $aptfile) {
		$conf->load($aptfile);
		$conf->{Enabled} = "yes";
		if($mirror){
			$conf->{'URIs'} = $mirror;
		}
		$conf->save($aptfile);
		print "Configuration for $reponame enabled.\n\nNote that configuration for this repository already existed; it was enabled, but not updated.\nFor updates, see the update command.\n";
		return;
	}

	my $ua = LWP::UserAgent->new;
	$ua->env_proxy;

	my $key_url = join('/', $config->{url}, $config->{dist}, $config->{version}, $repo->{"gpg-key-file"});
	my $response = $ua->get($key_url);
	if(!$response->is_success) {
		print "Could not download gpg public key for secure apt of repository $reponame:\n";
		die $response->status_line;
	}
	my $key_data = $response->decoded_content;
	if(sha256_hex($key_data) ne $repo->{"gpg-key-checksum"}{sha256}) {
		die "Could not enable repository $reponame: GPG key checksum is invalid!\n";
	}
	my @components;
	my $components;
	my $enabled = 0;
	my %enabled_policies;
	foreach my $policy(@{$config->{enabled_policies}}) {
		$enabled_policies{$policy}=1;
	}
	if(exists($repo->{policies})) {
		foreach my $component(keys %{$repo->{policies}}) {
			if(exists($enabled_policies{$repo->{policies}{$component}})) {
				push @components, $component;
			}
		}
		if(scalar(@components) > 0) {
			$enabled = 1;
		}
		$components = join(" ", @components);
	} else {
		if(grep({$_ eq $repo->{policy}} @{$config->{enabled_policies}})) {
			$enabled = 1;
		}
	}
	if(!$enabled) {
		die "None of the license inclusion policies in $reponame were enabled. Please edit /etc/extrepo/config.yaml and enable the required policies\n";
	}
	foreach my $key(keys %{$repo->{source}}) {
		my $value = $repo->{source}{$key};
		$value =~ s/<COMPONENTS>/$components/g;
		$conf->{$key} = $value;
	}

	# If the file existed already, and we're in update mode,
	# load the enabled/disabled value from it.
	if($update_mode && -f $aptfile) {
		my $temp_conf = Dpkg::Control::HashCore->new;
		$temp_conf->load($aptfile);
		$conf->{Enabled} = $temp_conf->{Enabled} if exists($temp_conf->{Enabled});
		print "Configuration for $reponame will be updated, but note the repository isn't enabled.\n" unless($conf->{Enabled});
	}


	my $key_file = "/var/lib/extrepo/keys/$reponame.asc";
	open my $key_fh, ">", "$key_file" or die "opening key file: $!";
	print $key_fh $key_data;
	close $key_fh;

	$conf->{"Signed-By"} = $key_file;

	if($mirror){
		$conf->{'URIs'} = $mirror;
	}

	$conf->save($aptfile) or die "writing apt config: $!\n";

	if(!$update_mode && exists($repo->{"post-enable-commands"})) {
		say "Running post-enable-commands for $reponame:";
		say "  " . join("\n  ", @{$repo->{"post-enable-commands"}});
		say "Interrupt (with Ctrl-C) in the next 10 seconds to prevent this from happening.\nNote that doing so may make your repository and/or your apt configuration unusable.";
		$| = 1;
		foreach my $count(1..10) {
			print "$count...";
			sleep 1;
		}
		$| = 0;
		say "you have been warned!";
		foreach my $command(@{$repo->{"post-enable-commands"}}) {
			system($command);
		}
	}
}

1;

package Debian::ExtRepo::Commands::Enable;

use strict;
use warnings;

use Debian::ExtRepo::Data qw/fetch_repodata/;
use Dpkg::Control::HashCore;
use LWP::UserAgent;
use Crypt::Digest::SHA256 qw/sha256_hex/;

sub run {
	my $config = shift;
	my $mirror = shift;
	my $update_mode = shift;
	my $reponame = shift;
	my $conf = Dpkg::Control::HashCore->new;

	die "Need to be root to modify external repository configuration!\n" unless($< == 0);

	umask 0022;

	my $extrepos = fetch_repodata($config);

	die "Repository $reponame does not exist!" unless exists($extrepos->{$reponame});
	my $repo = $extrepos->{$reponame};
	my $aptfile = "/etc/apt/sources.list.d/extrepo_$reponame.sources";

	if(!$update_mode && -f $aptfile) {
		$conf->load($aptfile);
		$conf->{Enabled} = "yes";
		if($mirror){
			$conf->{'URIs'} = $mirror;
		}
		$conf->save($aptfile);
		print "Configuration enabled.\n\nNote that configuration for this repository already existed; it was enabled, but not updated.\nFor updates, see the update command.\n";
		return;
	}

	my $ua = LWP::UserAgent->new;
	$ua->env_proxy;

	my $key_url = join('/', $config->{url}, $config->{dist}, $config->{version}, $repo->{"gpg-key-file"});
	my $response = $ua->get($key_url);
	if(!$response->is_success) {
		print "Could not download gpg public key for secure apt:\n";
		die $response->status_line;
	}
	my $key_data = $response->decoded_content;
	if(sha256_hex($key_data) ne $repo->{"gpg-key-checksum"}{sha256}) {
		die "Could not enable repository: GPG key checksum is invalid!\n";
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
		unless($conf->{Enabled}) {
			print "Configuration will be updated, but note the repository isn't enabled.\n";
		}
	}


	my $key_file = "/var/lib/extrepo/keys/$reponame.asc";
	open my $key_fh, ">$key_file" or die "opening key file: $!";
	print $key_fh $key_data;
	close $key_fh;

	$conf->{"Signed-By"} = $key_file;

	if($mirror){
		$conf->{'URIs'} = $mirror;
	}

	$conf->save($aptfile) or die "writing apt config: $!\n";
}

1;

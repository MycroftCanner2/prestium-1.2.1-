package Debian::ExtRepo::Data;

use v5.28;
use warnings;

use Exporter;
use YAML::XS qw/LoadFile/;
use LWP::UserAgent;
use File::Temp qw/tempdir tempfile/;

our @ISA = qw/Exporter/;

our @EXPORT_OK = qw/fetch_repodata fetch_config/;

sub fetch_config {
	return LoadFile('/etc/extrepo/config.yaml');
}

my $repodata;

sub fetch_repodata {
	my $config = shift;

	return $repodata if $repodata;

	my $ua = LWP::UserAgent->new;
	$ua->env_proxy;

	my $url = join('/', $config->{url}, $config->{dist}, $config->{version}, 'index.yaml');

	my $response = $ua->get($url);
	if(!$response->is_success) {
		print "Could not download index YAML file:\n";
		die $response->status_line;
	}

	my $extrepo_yaml = $response->decoded_content;

	my $dir = tempdir(CLEANUP => 1);
	my ($yaml_fh, $extrepo_yaml_file) = tempfile(DIR => $dir);
	binmode $yaml_fh, ':encoding(UTF-8)';
	print $yaml_fh $extrepo_yaml;
	close $yaml_fh;

        # If we're reading the extrepo's repo index from local filesytem's
        # extrepo-offline-data, we don't check the added gpg key, as we
        # assume gpg-extrepo-data is already GPG authenticated when installed
        # using apt/dpkg.
        if($config->{url} ne "file:///usr/share/extrepo/offline-data") {
		$response = $ua->get("$url.asc");
		if(!$response->is_success) {
			print "Could not download YAML file signature:\n";
			die $response->status_line;
		}

		my $extrepo_gpg = $response->decoded_content;
		my ($gpg_fh, $extrepo_gpg_file) = tempfile(DIR => $dir);
		print $gpg_fh $extrepo_gpg;
		close $gpg_fh;

		my $validated = 0;
		open my $gpgv, "-|", "gpgv --homedir /dev/null --keyring /etc/extrepo/keyring.gpg --status-fd 1 $extrepo_gpg_file $extrepo_yaml_file 2>/dev/null";
		while(<$gpgv>) {
			if(/VALIDSIG/) {
				$validated = 1;
				last;
			}
		}
		die "could not validate gpg signature, exiting\n" unless $validated;
		unlink($extrepo_gpg_file);
	}

	$repodata = LoadFile($extrepo_yaml_file);
	return $repodata;
}

1;

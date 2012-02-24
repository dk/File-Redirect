package File::Redirect;
use strict;
use warnings;
require DynaLoader;
our @EXPORT_OK = qw(mount umount);
our @ISA = qw(DynaLoader Exporter);
our $VERSION = '0.01';
bootstrap File::Redirect $VERSION;

use Errno;
our ($debug, %mounted);

$debug = 1 if $ENV{FILE_REDIRECT_DEBUG};

our $dev_no = 1_000_000;

sub debug($) { warn "$_[0]\n" }

sub mount
{
	my ( $provider, $request, $as_path ) = @_;

	die "$as_path already mounted" if exists $mounted{$as_path};

	debug "mount($provider, $request, $as_path)" if $debug;

	my $class = 'File::Redirect::' . $provider;
	eval "use $class;";
	die $@ if $@;

	$mounted{$as_path} = {
		request => $request,
		device  => $class-> mount( $request, $dev_no ),
		match   => qr/^\Q$as_path\E/,
		handles => {},
	};

	$dev_no++;
}

sub umount
{
	my ( $path ) = @_;
	
	debug "umount($path)" if $debug;
	
	return unless exists $mounted{$path};

	my $entry = delete $mounted{$path};
	$entry-> {device}-> Close($_) for values %{ $entry-> {handles} };
	$entry-> {device}-> umount;
	
	return 1;
}

END {
	my @mounted = keys %mounted; 
	umount($_) for @mounted;
};

sub to_entry
{
	my $path = shift;

	study $path;
	keys %mounted;
	while (my ($k,$v) = each %mounted) {
		return $v if $path =~ $v->{match};
	}
	return undef;
}

sub is_path_redirected { to_entry(@_) ? 1 : 0 }

sub Open
{
	my ($path, $mode) = @_;
	
	debug "open($path, $mode)" if $debug;

	my $entry = to_entry($path);
	return Errno::ENOENT() unless $entry;
	
	debug "device=$entry->{device}:$entry->{request}" if $debug;

	$path =~ s/$entry->{match}//;
	my $handle = $entry-> {device}-> Open($path, $mode);

	if ( ref $handle ) {
		my $iobase = File::Redirect::handle2iobase($handle);
		$entry-> {handles}-> {$iobase} = $handle;
		debug "success! handle=$handle, iobase=$iobase" if $debug;
	} else {
		debug "failed with $handle" if $debug;
	}

	return $handle;
}

sub Stat
{
	my ($path) = @_;

	debug "stat($path)" if $debug;

	my $entry = to_entry($path);
	return Errno::ENOENT() unless $entry;
	
	debug "device=$entry->{device}:$entry->{request}" if $debug;

	$path =~ s/$entry->{match}//;
	my $result = $entry-> {device}-> Stat($path);
	
	debug "result:$result" if $debug;

	return $result;
}

sub Close
{
	my $iobase = shift;
	
	debug "close($iobase)" if $debug;

	my ($entry, $handle);
	for ( values %mounted ) {
		next unless $handle = delete $_-> {handles}-> {$iobase};
		$entry = $_;
		last;
	}
	return Errno::ENOENT() unless $handle;
	
	debug "handle=$handle:device=$entry->{device}:$entry->{request}" if $debug;

	return $entry-> {device}-> Close($handle);
}

1;
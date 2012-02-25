package File::Redirect::lib;

use strict;
use warnings;
use File::Redirect qw(mount);

sub import {
	my ( undef, $provider, $request, $as_path, $root ) = @_;
	mount($provider, $request, $as_path);
	push @INC, "$as_path$root";
}

1;

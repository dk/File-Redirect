package File::Redirect::Base;

use strict;
use warnings;

use Errno;

sub mount  { die "not implemented" }
sub umount {}

sub Stat   { Errno::ENOENT() }
sub Open   { Errno::ENOENT() }
sub Close  { 0 }

1;

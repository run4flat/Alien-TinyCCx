########################################################################
                    package My::Build::BSD;
########################################################################

use strict;
use warnings;
use parent 'My::Build::Linux';

sub make_command { 'gmake' }

### MidnightBSD detection patch ###

my $is_midnight_handled = 0;

# Apply patch for MidnightBSD, and using cc instead of gcc
My::Build::apply_patches('src/configure' =>
	# Note if we have already taken care of midnight bsd or not
	qr/MidnightBSD\) noldl=yes;;/ => sub {
		$is_midnight_handled = 1;
		return 0;
	},
	qr/DragonFly\) noldl=yes;;/ => sub {
		my ($in_fh, $out_fh, $line) = @_;
		print $out_fh "  MidnightBSD) noldl=yes;;\n"
			unless $is_midnight_handled;
		return 0;
	},
	# normal "cc" compiler instead of gcc
	qr/cc="gcc"/ => sub {
		my ($in_fh, $out_fh, $line) = @_;
		$line =~ s/gcc/cc/;
		print $out_fh $line;
		return 1;
	}
);

# Apply patches for FreeBSD, which uses clang, but calls it cc
My::Build::apply_patches('src/Makefile' =>

	# Suck up the lines for identifying gnuisms: just apply them
	qr/ifneq.*findstring gcc.*CC.*gcc/ => sub {
		my ($in_fh, $out_fh, $line) = @_;
		$line = <$in_fh>; # skip ifeq clan
		$line = <$in_fh>; # skip comment line
		$line = <$in_fh>; # grab flag addendum line
		print $out_fh $line;
		$line = <$in_fh>; # skip endif
		$line = <$in_fh>; # skip endif
		return 0;
	},
);


1;

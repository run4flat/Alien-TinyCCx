use strict;
use warnings;

use Alien::TinyCCx;

# Needed for quick patching. I change the makefile so it does not
# execute or delete the tests, just creates them
use inc::My::Build;

# Run all of this from the test directory
chdir 'src';
chdir 'tests';
chdir 'exsymtab';

My::Build::apply_patches('Makefile' =>
	qr{lib_path=} => sub { 1 } # skip line
);

my $test_counter = 0;

sub test_compile {
	my ($test_file, $sys_cmd) = @_;
	my @compile_message = `$sys_cmd`;
	return 1 if ${^CHILD_ERROR_NATIVE} == 0;
	
	# Failed: explain
	print "  1..1\n";
	print "  not ok 1 - failed to compile:\n";
	print "# $_" foreach @compile_message;
	print "not ok $test_counter - $test_file\n";
}

# Run through all the tests in the test suite. Run each test as a
# subtest of this one.
for my $test_file (glob('*.c')) {
	
	# Skip files that are not test files
	next unless $test_file =~ /^\d\d-/;
	
	$test_counter++;
	
	# Print the test file name
	print "# $test_file\n";
	
	# Compile and run
	my @results;
	if ($^O =~ /Win32/) {
		next unless test_compile($test_file, 
			"gcc $test_file -I libtcc -I ..\\tests\\exsymtab -I .. -L lib libtcc.dll -o tcc-test.exe 2>&1");
		my @results = `tcc-test.exe lib_path=lib\\ 2>&1`;
	}
	else {
		my $test_name = $test_file;
		$test_name =~ s/\.c/.test/;
		next unless test_compile($test_file, "make $test_name");
		my @results = `./$test_name lib_path=../.. 2>&1`;
	}
	
	# See if we hit any errors during execution
	if (${^CHILD_ERROR_NATIVE} != 0) {
		print "  1..1\n";
		print "  not ok 1 - failed during execution:\n";
		print "#  $_" foreach (@results);
		print "not ok $test_counter - $test_file\n";
	}
	else {
		print "  $_" foreach (@results);
		print "ok $test_counter - $test_file\n";
	}
}

print "1..$test_counter\n";

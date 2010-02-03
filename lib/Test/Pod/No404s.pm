# Declare our package
package Test::Pod::No404s;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.01';

# Import the modules we need
use Pod::Simple::Text;
use LWP::UserAgent;
use URI::Find;
require Test::Pod;

# setup our tests and etc
use Test::Builder;
my $Test = Test::Builder->new;

# Thanks to Test::Pod for much of the code here!
sub import {
	my $self = shift;
	my $caller = caller;

	for my $func ( qw( pod_file_ok all_pod_files_ok ) ) {
		no strict 'refs';	## no critic ( ProhibitNoStrict )
		*{$caller."::".$func} = \&$func;
	}

	$Test->exported_to($caller);
	$Test->plan(@_);
}

sub pod_file_ok {
	my $file = shift;
	my $name = @_ ? shift : "404 test for $file";

	if ( ! -f $file ) {
		$Test->ok( 0, $name );
		$Test->diag( "$file does not exist" );
		return;
	}

	# Parse the POD!
	my $parser = Pod::Simple::Text->new;
	my $output;
	$parser->output_string( \$output );
	$parser->parse_file( $file );

	# is POD well-formed?
	if ( $parser->any_errata_seen ) {
		$Test->ok( 0, $name );
		$Test->diag( "Unable to parse POD in $file" );
		return 0;
	}

	# Did we see POD in the file?
	if ( $parser->doc_has_started ) {
		my @links;
		my $finder = URI::Find->new( sub {
			my $uri = shift;
			my $scheme = $uri->scheme;
			if ( defined $scheme and ( $scheme eq 'http' or $scheme eq 'https' ) ) {
				# Make sure we have unique links...
				if ( ! grep { $_->eq( $uri ) } @links ) {
					push @links, $uri;
				}
			}
		} );
		$finder->find( \$output );

		if ( scalar @links ) {
			# Verify the links!
			my $ok = 1;
			my @errors;
			my $ua = LWP::UserAgent->new;
			foreach my $l ( @links ) {
				my $response = $ua->head( $l );
				if ( $response->is_error ) {
					$ok = 0;
					push( @errors, [ $l->as_string, $response->status_line ] );
				}
			}

			if ( $ok ) {
				$Test->ok( 1, $name );
			} else {
				$Test->ok( 0, $name );
				foreach my $e ( @errors ) {
					$Test->diag( "Error retrieving '$e->[0]': $e->[1]" );
				}
			}
		} else {
			$Test->ok( 1, $name );
		}
	} else {
		$Test->ok( 1, $name );
	}

	return 1;
}

sub all_pod_files_ok {
	my @files = @_ ? @_ : Test::Pod::all_pod_files();

	$Test->plan( tests => scalar @files );

	my $ok = 1;
	foreach my $file ( @files ) {
		pod_file_ok( $file ) or undef $ok;
	}

	return $ok;
}

1;
__END__

=for stopwords LWP Kwalitee TESTNAME env internet

=head1 NAME

Test::Pod::No404s - Checks POD for http 404 links

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;

	use Test::More;

	eval "use Test::Pod::No404s";
	if ( $@ ) {
		plan skip_all => 'Test::Pod::No404s required for testing POD';
	} else {
		all_pod_files_ok();
	}

=head1 ABSTRACT

Using this test module will check your POD for any http 404 links.

=head1 DESCRIPTION

This module looks for any http(s) links in your POD and verifies that they will not return a 404. It uses L<LWP::UserAgent> for the heavy
lifting, and simply lets you know if it failed to retrieve the document. More specifically, it uses $response->is_error as the "test."

Normally, you wouldn't want this test to be run during end-user installation because they might have no internet! It is HIGHLY recommended
that this be used only for module authors' RELEASE_TESTING phase. To do that, just modify the synopsis to add an env check :)

=head1 Methods

=head2 all_pod_files_ok( [ @files ] )

This function is what you will usually run. It automatically finds any POD in your distribution and runs checks on them.

Accepts an optional argument: an array of files to check. By default it checks all POD files it can find in the distribution. Every file it finds
is passed to the C<pod_file_ok> function.

=head2 pod_file_ok( FILENAME, [ TESTNAME ] )

C<pod_file_ok()> will okay the test if there is no http(s) links present in the POD or if all links are not an error. Furthermore, if the POD was
malformed as reported by L<Pod::Simple>, the test will fail and not attempt to check the links.

When it fails, C<pod_file_ok()> will show any failing links as diagnostics.

The optional second argument TESTNAME is the name of the test.  If it is omitted, C<pod_file_ok()> chooses a default
test name "404 test for FILENAME".

=head1 EXPORT

Automatically exports the two subs.

=head1 SEE ALSO

L<LWP::UserAgent>

L<Pod::Simple>

L<Test::Pod>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pod::No404s

=head2 Websites

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Pod-No404s>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Pod-No404s>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Pod-No404s>

=item * CPAN Forum

L<http://cpanforum.com/dist/Test-Pod-No404s>

=item * RT: CPAN's Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pod-No404s>

=item * CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Test-Pod-No404s>

=item * CPAN Testers Results

L<http://cpantesters.org/distro/T/Test-Pod-No404s.html>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Test-Pod-No404s>

=item * Git Source Code Repository

L<http://github.com/apocalypse/perl-test-pod-no404s>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-test-pod-no404s at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pod-No404s>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Thanks to the author of L<Test::Pod> for the basic framework of this module!

Thanks to the POE guys for finding 404 links in their POD, and was the inspiration for this module.

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

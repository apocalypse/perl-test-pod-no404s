# Build.PL
use strict; use warnings;
use Module::Build;

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'Test::Pod::No404s',
	'license'		=> 'perl',

	'dist_abstract'		=> 'Checks POD for http 404 links',
	'dist_author'		=> 'Apocalypse <APOCAL@cpan.org>',

	'create_packlist'	=> 1,
	'create_makefile_pl'	=> 'traditional',
	'create_readme'		=> 1,
	'create_license'	=> 1,
	'sign'			=> 0,

	'test_files'		=> 't/*.t',

	'add_to_cleanup'	=> [ 'META.yml', 'Makefile.PL', 'README', 'Makefile', 'LICENSE' ], # automatically generated

	'requires'		=> {
		# Test stuff
		'Test::Builder'			=> '0.94',
		'Test::Pod'			=> '1.40',

		# handy tools
		'LWP::UserAgent'		=> '5.834',
		'Pod::Simple::Text'		=> '3.13',
		'URI::Find'			=> '20090319',

		# we need a recent perl
		'perl'				=> '5.008',
	},

	# include the standard stuff in META.yml
	'meta_merge'	=> {
		'resources'	=> {
			'license'	=> 'http://dev.perl.org/licenses/',
			'homepage'	=> 'http://search.cpan.org/dist/Test-Pod-No404s',
			'bugtracker'	=> 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pod-No404s',
			'repository'	=> 'http://github.com/apocalypse/perl-test-pod-no404s',
		},
	},
);

# all done!
$build->create_build_script;

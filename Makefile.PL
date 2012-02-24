use ExtUtils::MakeMaker;
require 5.010_000;
WriteMakefile(
	NAME		=> 'File::Redirect',
	VERSION_FROM	=> 'lib/File/Redirect.pm',
	META_MERGE        => {
		resources => {
			repository => 'http://github.com/dk/File-Redirect',
		},
	},
);

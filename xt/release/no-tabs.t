use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'examples/no_plan.t',
    'examples/sub.t',
    'examples/synopsis_1.t',
    'examples/synopsis_2.t',
    'examples/test_nowarnings.pl',
    'examples/test_warning_contents.t',
    'examples/warning_like.t',
    'examples/with_done_testing.t',
    'examples/with_plan.t',
    'lib/Test/Warnings.pm'
);

notabs_ok($_) foreach @files;
done_testing;

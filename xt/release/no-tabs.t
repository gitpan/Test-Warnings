use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'examples/no_plan.t',
    'examples/sub.t',
    'examples/synopsis_1.t',
    'examples/synopsis_2.t',
    'examples/test_nowarnings.t',
    'examples/test_warning_contents.t',
    'examples/warning_like.t',
    'examples/with_done_testing.t',
    'examples/with_plan.t',
    'lib/Test/Warnings.pm',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-done_testing.t',
    't/03-subtest.t',
    't/04-no-tests.t',
    't/05-no-end-block.t',
    't/06-skip-all.t',
    't/07-no_plan.t',
    't/08-use-if.t',
    't/09-warnings-contents.t',
    't/10-no-done_testing.t',
    't/11-double-use.t',
    'xt/author/00-compile.t',
    'xt/author/examples_synopsis_1.t',
    'xt/author/examples_synopsis_2.t',
    'xt/author/examples_test_warning_contents.t',
    'xt/author/pod-spell.t',
    'xt/release/changes_has_content.t',
    'xt/release/clean-namespaces.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/eol.t',
    'xt/release/kwalitee.t',
    'xt/release/minimum-version.t',
    'xt/release/mojibake.t',
    'xt/release/no-tabs.t',
    'xt/release/pod-coverage.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

notabs_ok($_) foreach @files;
done_testing;

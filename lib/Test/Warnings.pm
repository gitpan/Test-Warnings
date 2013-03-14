use strict;
use warnings;
package Test::Warnings;
{
  $Test::Warnings::VERSION = '0.002';
}
# git description: v0.001-TRIAL-12-gca0403c

BEGIN {
  $Test::Warnings::AUTHORITY = 'cpan:ETHER';
}
# ABSTRACT: Test for warnings and the lack of them

use parent 'Exporter';
use Test::Builder;
use Class::Method::Modifiers ();

our @EXPORT_OK = qw(allow_warnings allowing_warnings had_no_warnings);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my $warnings_allowed;
my $forbidden_warnings_found;
my $done_testing_called;
my $no_end_test;

sub import
{
    # END block will check for this status
    my @symbols = grep { $_ ne ':no_end_test' } @_;
    $no_end_test = (@symbols != @_);

    __PACKAGE__->export_to_level(1, @symbols);
}

# for testing this module only!
my $tb;
sub _builder(;$)
{
    if (not @_)
    {
        $tb ||= Test::Builder->new;
        return $tb;
    }

    $tb = shift;
}

$SIG{__WARN__} = sub {
    my $msg = shift;
    warn $msg;
    $forbidden_warnings_found++ if not $warnings_allowed;
};

if (Test::Builder->can('done_testing'))
{
    # monkeypatch Test::Builder::done_testing:
    # check for any forbidden warnings, and record that we have done so
    # so we do not check again via END
    Class::Method::Modifiers::install_modifier('Test::Builder',
        before => done_testing => sub {
            # only do this at the end of all tests, not at the end of a subtest
            if (not _builder()->parent)
            {
                local $Test::Builder::Level = $Test::Builder::Level + 3;
                had_no_warnings('no (unexpected) warnings (via done_testing)');
                $done_testing_called = 1;
            }
        },
    );
}

END {
    if (not $no_end_test
        and not $done_testing_called
        # skip this if there is no plan and no tests were run (e.g.
        # compilation tests of this module!)
        and (_builder->expected_tests or ref(_builder) ne 'Test::Builder')
        and _builder->current_test > 0
    )
    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        had_no_warnings('no (unexpected) warnings (via END block)');
    }
}

# setter
sub allow_warnings(;$)
{
    $warnings_allowed = @_ || defined $_[0] ? $_[0] : 1;
}

# getter
sub allowing_warnings() { $warnings_allowed }

# call at any time to assert no (unexpected) warnings so far
sub had_no_warnings(;$)
{
    _builder()->ok(!$forbidden_warnings_found, shift || 'no (unexpected) warnings');
}

1;

__END__

=pod

=head1 NAME

Test::Warnings - Test for warnings and the lack of them

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Test::More;
    use Test::Warnings;

    pass('yay!');
    done_testing;

emits TAP:

    ok 1 - yay!
    ok 2 - no (unexpected) warnings (via done_testing)
    1..2

=head1 DESCRIPTION

If you've ever tried to use L<Test::NoWarnings> to confirm there are no warnings
generated by your tests, combined with the convenience of C<done_testing> to
not have to declare a
L<test count|Test::More/I love it-when-a-plan-comes-together>,
you'll have discovered that these two features do not play well together,
as the test count will be calculated I<before> the warnings test is run,
resulting in a TAP error. (See C<examples/test_nowarnings.pl> in this
distribution for a demonstration.)

This module is intended to be used as a drop-in replacement for
L<Test::NoWarnings>: it also adds an extra test, but runs this test I<before>
C<done_testing> calculates the test count, rather than after.  It does this by
hooking into C<done_testing> as well as via an C<END> block.  You can declare
a plan, or not, and things will still Just Work.

It is actually equivalent to:

    use Test::NoWarnings 1.04 ':early';

as warnings are still printed normally as they occur.  You are safe, and
enthusiastically encouraged, to perform a global search-replace of the above
with C<use Test::Warnings;> whether or not your tests have a plan.

=head1 FUNCTIONS

The following functions are available for import (not included by default; you
can also get all of them by importing the tag C<:all>):

=over

=item * C<< allow_warnings([bool]) >> - EXPERIMENTAL - MAY BE REMOVED

When passed a true value, or no value at all, subsequent warnings will not
result in a test failure; when passed a false value, subsequent warnings will
result in a test failure.  Initial value is C<false>.

=item * C<allowing_warnings> - EXPERIMENTAL - MAY BE REMOVED

Returns whether we are currently allowing warnings (set by C<allow_warnings>
as described above).

=item * C<< had_no_warnings(<optional test name>) >>

Tests whether there have been any warnings so far, not preceded by an
C<allowing_warnings> call.  It is run
automatically at the end of all tests, but can also be called manually at any
time, as often as desired.

=back

=head1 OTHER OPTIONS

=over

=item * C<:all> - Imports all functions listed above

=item * C<:no_end_test> - Disables the addition of a C<had_no_warnings> test via END (but if you don't want to do this, you probably shouldn't be loading this module at all!)

=back

=head1 TO DO (i.e. FUTURE FEATURES, MAYBE)

=over

=item * C<< allow_warnings(qr/.../) >> - allow some warnings and not others

=item * C<< warning_is, warning_like etc... >> - inclusion of some
L<Test::Warn>-like functionality for testing the content of warnings, but
closer to a L<Test::Fatal>-like syntax

=item * more sophisticated handling in subtests - if we save some state on the
L<Test::Builder> object itself, we can allow warnings in a subtest and then
the state will revert when the subtest ends, as well as check for warnings at
the end of every subtest via C<done_testing>.

=back

=head1 SUPPORT

Bugs may be submitted through L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Warnings>.
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

L<Test::NoWarnings>

L<Test::FailWarnings>

L<blogs.perl.org: YANWT (Yet Another No-Warnings Tester)|http://blogs.perl.org/users/ether/2013/03/yanwt-yet-another-no-warnings-tester.html>

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

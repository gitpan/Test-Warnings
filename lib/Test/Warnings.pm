use strict;
use warnings;
package Test::Warnings;
{
  $Test::Warnings::VERSION = '0.006';
}
# git description: v0.005-3-gf277067

BEGIN {
  $Test::Warnings::AUTHORITY = 'cpan:ETHER';
}
# ABSTRACT: Test for warnings and the lack of them

use parent 'Exporter';
use Test::Builder;

our @EXPORT_OK = qw(
    allow_warnings allowing_warnings
    had_no_warnings
    warnings warning
);
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

    if ($warnings_allowed)
    {
        Test::Builder->new->note($msg);
    }
    else
    {
        warn $msg;
        $forbidden_warnings_found++;
    }
};

sub warnings(&)
{
    my $code = shift;
    my @warnings;
    local $SIG{__WARN__} = sub {
        push @warnings, shift;
    };
    $code->();
    @warnings;
}

sub warning(&)
{
    my @warnings = &warnings(@_);
    return @warnings == 1 ? $warnings[0] : \@warnings;
}

if (Test::Builder->can('done_testing'))
{
    # monkeypatch Test::Builder::done_testing:
    # check for any forbidden warnings, and record that we have done so
    # so we do not check again via END

    no strict 'refs';
    my $orig = *{'Test::Builder::done_testing'}{CODE};
    no warnings 'redefine';
    *{'Test::Builder::done_testing'} = sub {
        # only do this at the end of all tests, not at the end of a subtest
        my $builder = _builder;
        my $in_subtest_sub = $builder->can('in_subtest');
        if (not ($in_subtest_sub ? $builder->$in_subtest_sub : $builder->parent))
        {
            local $Test::Builder::Level = $Test::Builder::Level + 3;
            had_no_warnings('no (unexpected) warnings (via done_testing)');
            $done_testing_called = 1;
        }

        $orig->(@_);
    };
}

END {
    if (not $no_end_test
        and not $done_testing_called
        # skip this if there is no plan and no tests have been run (e.g.
        # compilation tests of this module!)
        and (_builder->expected_tests or _builder->current_test > 0)
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
    _builder->ok(!$forbidden_warnings_found, shift || 'no (unexpected) warnings');
}

1;

__END__

=pod

=encoding utf-8

=for :stopwords Karen Etheridge Graham Knop Leon Timmermans smartmatch TODO subtest
subtests irc YANWT

=head1 NAME

Test::Warnings - Test for warnings and the lack of them

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use Test::More;
    use Test::Warnings;

    pass('yay!');
    like(warning { warn "oh noes!" }, qr/^oh noes/, 'we warned');
    done_testing;

emits TAP:

    ok 1 - yay!
    ok 2 - we warned
    ok 3 - no (unexpected) warnings (via done_testing)
    1..3

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

When warnings are allowed, any warnings will instead be emitted via
L<Test::Builder::note|Test::Builder/Output>.

=item * C<allowing_warnings> - EXPERIMENTAL - MAY BE REMOVED

Returns whether we are currently allowing warnings (set by C<allow_warnings>
as described above).

=item * C<< had_no_warnings(<optional test name>) >>

Tests whether there have been any warnings so far, not preceded by an
C<allowing_warnings> call.  It is run
automatically at the end of all tests, but can also be called manually at any
time, as often as desired.

=item * C<< warnings( { code } ) >>

Given a code block, runs the block and returns a list of all the
(not previously allowed via C<allow_warnings>) warnings issued within.  This
lets you test for the presence of warnings that you not only would I<allow>,
but I<must> be issued.  Testing functions are not provided; given the strings
returned, you can test these yourself using your favourite testing functions,
such as L<Test::More::is|Test::More> or L<Test::Deep::cmp_deeply|Test::Deep>.

Warnings generated by this code block are I<NOT> propagated further. However,
since they are returned from this function with their filename and line
numbers intact, you can re-issue them yourself immediately after calling
C<warnings(...)>, if desired.

=item * C<< warning( { code } ) >>

Same as C<< warnings( { code } ) >>, except a scalar is always returned - the
single warning produced, if there was one, or an arrayref otherwise -- which
can be more convenient to use than C<warnings()> if you are expecting exactly
one warning.

=back

=head1 OTHER OPTIONS

=over

=item * C<:all> - Imports all functions listed above

=item * C<:no_end_test> - Disables the addition of a C<had_no_warnings> test via END (but if you don't want to do this, you probably shouldn't be loading this module at all!)

=back

=head1 CAVEATS

Sometimes new warnings can appear in Perl that should B<not> block
installation -- for example, smartmatch was recently deprecated in
perl 5.17.11, so now any distribution that uses smartmatch and also
tests for warnings cannot be installed under 5.18.0.  You might want to
consider only making warnings fail tests in an author environment -- you can
do this with the L<if> pragma:

    use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

In future versions of this module, when interfaces are added to test the
content of warnings, there will likely be additional sugar available to
indicate that warnings should be checked only in author tests (or TODO when
not in author testing), but will still provide exported subs.  Comments are
enthusiastically solicited - drop me an email, write up an RT ticket, or come
by C<#perl-qa> on irc!

=head1 TO DO (i.e. POSSIBLE FEATURES COMING IN FUTURE RELEASES)

=over

=item * C<< allow_warnings(qr/.../) >> - allow some warnings and not others

=item * more sophisticated handling in subtests - if we save some state on the
L<Test::Builder> object itself, we can allow warnings in a subtest and then
the state will revert when the subtest ends, as well as check for warnings at
the end of every subtest via C<done_testing>.

=item * sugar for making failures TODO when testing outside an author
environment

=back

=head1 SUPPORT

Bugs may be submitted through L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Warnings>.
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Test::NoWarnings>

=item *

L<Test::FailWarnings>

=item *

L<blogs.perl.org: YANWT (Yet Another No-Warnings Tester)|http://blogs.perl.org/users/ether/2013/03/yanwt-yet-another-no-warnings-tester.html>

=item *

L<strictures> - which makes all warnings fatal in tests, hence lessening

the need for special warning testing

=back

L<Test::Warn>

L<Test::Fatal>

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=over 4

=item *

Graham Knop <haarg@haarg.org>

=item *

Leon Timmermans <fawaka@gmail.com>

=back

=cut

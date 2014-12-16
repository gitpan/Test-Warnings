use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Warnings ':no_end_test', 'warnings';

{
    my ($line, $file);

    is_deeply(
        [ warnings { warn "a normal warning"; $line = __LINE__; $file = __FILE__ } ],
        [ "a normal warning at $file line $line.\n" ],
        'test the appearance of a normal warning',
    );
}

{
    my ($line, $file);
    my $original_handler = $SIG{__WARN__};

    is_deeply(
        [ warnings { $original_handler->('a warning with no newline'); $line = __LINE__; $file = __FILE__ } ],
        [ "a warning with no newline at $file line $line.\n" ],
        'warning has origin properly added when it was lacking',
    );
}

done_testing;

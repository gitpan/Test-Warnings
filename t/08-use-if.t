use strict;
use warnings FATAL => 'all';

use Test::More 0.88;

pass 'here is a passing test, to keep plan happy';

BEGIN { $ENV{FOO} = $ENV{BAR} = 0 };
use if $ENV{FOO} || $ENV{BAR}, 'Test::Warnings';

warn 'this is not a fatal warning, because Test::Warnings is not loaded';

done_testing;

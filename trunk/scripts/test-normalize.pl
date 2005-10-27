#!/usr/bin/perl -I ../lib

use strict;
use FileInfo::Utils;

my $string=shift;
my $date=shift;

print "Initial string is: \[$string\]\n";
FileInfo::Utils::normalize_string(\$string);
print "Result string is: \[$string\]\n";

print "Initial date is: \[$date\]\n";
FileInfo::Utils::normalize_date(\$date);
print "Result date is: \[$date\]\n";

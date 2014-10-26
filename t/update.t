#!perl -T

use strict;
use warnings;
use Test::More tests => 9;
use FindBin qw($Bin);
use Data::Dumper;

( my $test_dir ) = $Bin =~ m:^(.*?/t)$:;

( my $data_dir ) = "$test_dir/data"          =~ m:^(.*/data)$:;
( my $db_file )  = "$data_dir/nvdcve-2.0.db" =~ /^(.*db)$/;

BEGIN {
    use_ok('NIST::NVD::Query') || print "Bail out!";
}

# Verify that each function returns expected result

my $q;

$q = eval {
    NIST::NVD::Query->new( store => 'SQLite3', database => $db_file, );
};

ok( !$@, "no error" ) or diag $@;

is( ref $q, 'NIST::NVD::Query',
    'constructor returned an object of correct class' );

my $cve_id_list;

$cve_id_list = $q->cve_for_cpe( cpe => 'cpe:/a:microsoft:ie:7.0.5730.11' );

is( ref $cve_id_list, 'ARRAY', 'cve_for_cpe returned ARRAY ref' );

is( int(@$cve_id_list), 1, 'correct number of CVEs returned for this CPE' );

foreach my $cve_entry (@$cve_id_list) {
    like( $cve_entry, qr{^CVE-\d{4,}-\d{4}$}, 'format of CVE ID is correct' );
}

is_deeply( $cve_id_list, ['CVE-2010-5071'], 'Correct list of CVE IDs' )
    or diag Data::Dumper::Dumper($cve_id_list);

my $entry = $q->cve( cve_id => $cve_id_list->[0] );

is( ref $entry, 'HASH', 'CVE entry is a HASH ref' );

my $cvss = $entry->{'vuln:cvss'};

is_deeply(
    $cvss,
    {   'cvss:base_metrics' => {
            'cvss:confidentiality-impact' => 'PARTIAL',
            'cvss:score'                  => '5.0',
            'cvss:authentication'         => 'NONE',
            'cvss:access-vector'          => 'NETWORK',
            'cvss:source'                 => 'http://nvd.nist.gov',
            'cvss:generated-on-datetime'  => '2011-12-08T08:04:00.000-05:00',
            'cvss:availability-impact'    => 'NONE',
            'cvss:integrity-impact'       => 'NONE',
            'cvss:access-complexity'      => 'LOW'
        }
    },
    'extracting cvss worked'
) or diag Data::Dumper::Dumper($cvss);


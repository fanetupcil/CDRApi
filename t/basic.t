use Mojo::Base -strict;
use lib '/home/stefan/Documents/cdrapi';
use lib '/home/stefan/Documents/cdrapi/lib';
use Test::More;
use Test::Mojo;
use Text::CSV_XS;
use CDRApi::Model::DB;
use Data::Dumper;

# Create a test database connection
### modify file path before running
my $file_path = '/home/stefan/Documents/cdrapi/t/tet.csv';
truncate_table();

my $t = Test::Mojo->new('CDRApi');

### File upload
$t->post_ok( '/data/load' => form => { file => { file => $file_path } } )
  ->status_is(200)->json_is( '/message' => "CSV Imported " );

### get CDRS by reference
$t->get_ok('/cdrs/reference/CFD0F0B32F61D287CF34CD3DC43EDF87F')->status_is(200)
  ->content_type_is('application/json;charset=UTF-8')->json_is(
    [
        {
            "call_date" => "2016-08-18",
            "caller_id" => 442036000000,
            "cost"      => "0.001",
            "currency"  => "GBP",
            "duration"  => 6,
            "end_time"  => "17:08:34",
            "recipient" => 447910000000,
            "reference" => "CFD0F0B32F61D287CF34CD3DC43EDF87F",
            "type"      => "2"
        }
    ]
  );

$t->get_ok('/cdrs/reference/C2BF812F9B32CD37164AB07C69A36111D')->status_is(200)
  ->content_type_is('application/json;charset=UTF-8')->json_is(
    [
        {
            "call_date" => "2016-08-16",
            "caller_id" => 442036000000,
            "cost"      => "0.000",
            "currency"  => "GBP",
            "duration"  => 693,
            "end_time"  => "14:32:48",
            "recipient" => 448005000000,
            "reference" => "C2BF812F9B32CD37164AB07C69A36111D",
            "type"      => "2"
        }
    ]
  );

$t->get_ok('/cdrs/reference/C')->status_is(200)
  ->content_type_is('application/json;charset=UTF-8')->json_is( [] );

$t->get_ok('/cdrs/stats?start_date=2016-08-01&end_date=2016-08-28&call_type=2')
  ->status_is(200)->content_type_is('application/json;charset=UTF-8')
  ->json_is( { "call_count" => 141, "total_duration" => "19428" } );

$t->get_ok('/cdrs/stats?start_date=2016-08-01&end_date=2016-08-28&call_type=3')
  ->status_is(400)->content_type_is('application/json;charset=UTF-8')
  ->json_is( { "error" => "Invalid parameters" } );

$t->get_ok(
'/cdrs/caller?start_date=2016-08-01&end_date=2016-08-20&call_type=2&caller_id=443330000000'
)->status_is(200)->content_type_is('application/json;charset=UTF-8');

my $json_data = $t->tx->res->json;

#diag("JSON response: " . Dumper($json_data));
isa_ok( $json_data, 'ARRAY', 'JSON response is an array' );

# Iterate over the array
for my $item (@$json_data) {
    pass('Array item exists') if $item;

    like( $item->{call_date}, qr/^\d{4}-\d{2}-\d{2}$/,
        'call_date has correct format' );
    like( $item->{caller_id}, qr/^\d+$/,       'caller_id has correct format' );
    like( $item->{recipient}, qr/^\d+$/,       'recipient has correct format' );
    like( $item->{reference}, qr/^[A-F0-9]+$/, 'reference has correct format' );
}

$t->get_ok(
'/cdrs/most_expensive/?start_date=2016-08-01&end_date=2016-08-28&call_type=2&caller_id=442036000000&n=1000'
)->status_is(200)->content_type_is('application/json;charset=UTF-8');
$json_data = $t->tx->res->json;

#diag("JSON response: " . Dumper($json_data));
isa_ok( $json_data, 'ARRAY', 'JSON response is an array' );

# Iterate over the array
for my $item (@$json_data) {
    pass('Array item exists') if $item;

    like( $item->{call_date}, qr/^\d{4}-\d{2}-\d{2}$/,
        'call_date has correct format' );
    like( $item->{caller_id}, qr/^\d+$/, 'caller_id has correct format' );
    like( $item->{cost},      qr/^\d+\.\d{3}$/, 'cost has correct format' );
    like( $item->{duration},  qr/^\d+/,         'duration has correct format' );
    like( $item->{end_time}, qr/^\d{2}:\d{2}:\d{2}$/,
        'end_time has correct format' );
    like( $item->{recipient}, qr/^\d+$/,       'recipient has correct format' );
    like( $item->{reference}, qr/^[A-F0-9]+$/, 'reference has correct format' );
    like( $item->{type},      qr/^\d$/,        'type has correct format' );
}

done_testing();

sub truncate_table {

    my $dbh    = CDRApi::Model::DB->new();
    my $cdr_rs = $dbh->resultset('CallRecord');
    $cdr_rs->delete();
}

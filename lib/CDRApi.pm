package CDRApi;
use lib '/home/stefan/Documents/cdrapi/lib';

use Mojo::Base 'Mojolicious', -signatures;
use Mojo::Content::Single;
use Mojo::Upload;
use Mojo::IOLoop;
use Mojo::Promise;

use CDRApi::Model::DB;

# This method will run once at server start
sub startup ($self) {

    # Load configuration from config file
    my $config = $self->plugin('NotYAMLConfig');

    # Configure the application
    $self->secrets( $config->{secrets} );

    $self->_db_handler();

    # Router
    my $r = $self->routes;

    #setting the request size (for file upload)
    $self->max_request_size( $self->app->config->{max_request_size} );

    # Retrieve individual CDR by the CDR Reference:
    $r->get('/cdrs/reference/:reference')
      ->to( controller => 'Cdr', action => 'get_cdr_by_reference' );

  # Retrieve a count and total duration of all calls in a specified time period:

    $r->get('/cdrs/stats')
      ->to( controller => 'Cdr', action => 'get_call_stats' );

    # Retrieve all CDRs for a specific Caller ID in a specified time period:

    $r->get('/cdrs/caller')
      ->to( controller => 'Cdr', action => 'get_cdr_by_callerid' );

    #Retrieve N most expensive calls, in GBP,
    $r->get('/cdrs/most_expensive')
      ->to( controller => 'Cdr', action => 'get_most_expensive_calls' );

    # Upload and load data from file
    $r->post('/data/load')
      ->to( controller => 'Data', action => 'upload_and_load' );

}

sub _db_handler {
    my $self = shift;
    $self->{dbh} = CDRApi::Model::DB->new();
    return $self;
}

1;

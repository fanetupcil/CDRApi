package CDRApi;
use lib '/home/stefan/Documents/CDRApi/lib';

use Mojo::Base 'Mojolicious', -signatures;
use Mojo::Content::Single;
use Mojo::Upload;
use Mojo::IOLoop;
use Mojo::Promise;

use CDRApi::Model::DB;

# This method will run once at server start
sub startup ($self) {
    my $config = $self->plugin('NotYAMLConfig');

    $self->secrets( $config->{secrets} );
    $self->_db_handler();

    my $r = $self->routes;

    #setting the request size (for file upload)
    $self->max_request_size( $self->app->config->{max_request_size} );

    my $v1   = $r->under('/v1');
    my $cdrs = $v1->under('/cdrs');

    $cdrs->get('/stats')
      ->to( controller => 'Cdr', action => 'get_calls_stats' );

    $cdrs->get('/')->to( controller => 'Cdr', action => 'get_filtered_cdrs' );

    $cdrs->get('/:reference')
      ->to( controller => 'Cdr', action => 'get_cdr_by_reference' );

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

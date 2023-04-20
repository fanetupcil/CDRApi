package CDRApi::Controller::Cdr;
use lib '/home/stefan/Documents/CDRApi/lib';

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::Promise;
use CDRApi::Model::CdrModel;



sub get_cdr_by_reference ($self) {
    my $dbh       = $self->app->{dbh};
    my $reference = $self->stash('reference');
    my $cdr_model = CDRApi::Model::CdrModel->new( $self->app->{dbh} );

    my $rs =  $cdr_model->get_cdr_by_reference($reference);

    $self->render( json => $rs  );
}

sub get_calls_stats ($self) {
    my $start_date = $self->param('start_date');
    my $end_date   = $self->param('end_date');
    my $call_type  = $self->param('call_type');

    my $v   = $self->validation;
    my $cdr_model = CDRApi::Model::CdrModel->new( $self->app->{dbh} );

    $v->required('start_date')->like(qr/\d{4}\-\d{2}-\d/);
    $v->required('end_date')->like(qr/\d{4}\-\d{2}-\d/);
    $v->optional('call_type')->in( '1',    '2' );
use Data::Dumper; print Dumper "intrat";
# Verify that the distance between start date and end date is not longer than one month and the params
    return
      if ( $self->check_params( $start_date, $end_date, $v ) );

    my $rs = $cdr_model->get_calls_stats($start_date, $end_date, $call_type);

    $self->render( json => $rs );

}

sub get_filtered_cdrs ($self) {
    my $start_date = $self->param('start_date');
    my $end_date   = $self->param('end_date');
    my $caller_id  = $self->param('caller_id');
    my $call_type  = $self->param('call_type');
    my $n          = $self->param('n');

    my $v   = $self->validation;
    my $cdr_model = CDRApi::Model::CdrModel->new( $self->app->{dbh} );

    $v->required('start_date')->like(qr/\d{4}\-\d{2}-\d/);
    $v->required('end_date')->like(qr/\d{4}\-\d{2}-\d/);
    $v->optional('call_type')->in( '1', '2' );
    $v->required('caller_id')->like(qr/\d+/);
    $v->optional('n')->like(qr/\d+/);

    return
      if ( $self->check_params( $start_date, $end_date, $v ) );

    my $rs = $cdr_model->get_filtered_cdrs($start_date, $end_date, $caller_id, $call_type, $n);

    $self->render( json => $rs );

}

sub check_params ( $self, $start_date, $end_date, $v ) {
    my $start_dt = DateTime->new(
        year  => substr( $start_date, 0, 4 ),
        month => substr( $start_date, 5, 2 ),
        day   => substr( $start_date, 8, 2 )
    );

    my $end_dt = DateTime->new(
        year  => substr( $end_date, 0, 4 ),
        month => substr( $end_date, 5, 2 ),
        day   => substr( $end_date, 8, 2 )
    );
    my $interval = $end_dt->subtract_datetime($start_dt);

    #If date interval is bigger than 1 month
    if ( $interval->{months} > 1
        || ( $interval->{months} == 1 && $interval->{days} >= 1 ) )
    {
        $self->render(
            status => 400,
            json   => {
                error =>
                  'Error: Call date interval cannot be longer than one month.'
            }
        );
        return 1;
    }

    if ( $v->has_error ) {
        $self->render(
            status => 400,
            json   => { error => "Invalid parameters" },
        );
        return 1;
    }

    return 0;

}

1;

package CDRApi::Controller::Cdr;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub get_cdr_by_reference ($self) {
    my $dbh       = $self->app->{dbh};           # Database handler
    my $reference = $self->stash('reference');

    # Fetch all the threads from the thread table;
    my @rs =
      $dbh->resultset('CallRecord')->search( { reference => $reference } );

    @rs = map {
        {
            caller_id => $_->caller_id,
            recipient => $_->recipient,
            call_date => $_->call_date->ymd,
            end_time  => $_->end_time,
            duration  => $_->duration,
            cost      => $_->cost,
            reference => $_->reference,
            currency  => $_->currency,
            type      => $_->type
        }
    } @rs;
    $self->render( json => \@rs );

}

sub get_call_stats ($self) {
    my $start_date = $self->param('start_date');
    my $end_date   = $self->param('end_date');
    my $caller_id  = $self->param('caller_id');
    my $call_type  = $self->param('call_type');

    my $result;
    my $dbh = $self->app->{dbh};
    my $v   = $self->validation;

    $v->required('start_date')->like(qr/\d{4}\-\d{2}-\d/);
    $v->required('end_date')->like(qr/\d{4}\-\d{2}-\d/);
    $v->optional('aggregate')->in( 'true', 'false' );
    $v->optional('call_type')->in( '1',    '2' );

# Verify that the distance between start date and end date is not longer than one month and the params
    return
      if ( $self->check_params( $start_date, $end_date, $v ) );

    my $rs = $dbh->resultset('CallRecord')->search(
        {
            call_date => {
                '>=' => $start_date,
                '<'  => $end_date,
            },
            $call_type ? ( type => $call_type ) : (),
        },
        {
            select => [ { count => '*' }, { sum => 'duration' }, ],
            as     => [qw(call_count total_duration)],
        },
    );

    $result = $rs->next;

    $result = {
        call_count     => $result->get_column('call_count'),
        total_duration => $result->get_column('total_duration') || '0'
    };

    $self->render( json => $result );

}

sub get_cdr_by_callerid ($self) {
    my $start_date = $self->param('start_date');
    my $end_date   = $self->param('end_date');
    my $caller_id  = $self->param('caller_id');
    my $call_type  = $self->param('call_type');

    my $result;
    my $dbh = $self->app->{dbh};
    my $v   = $self->validation;

    $v->required('start_date')->like(qr/\d{4}\-\d{2}-\d/);
    $v->required('end_date')->like(qr/\d{4}\-\d{2}-\d/);
    $v->optional('call_type')->in( '1', '2' );
    $v->required('caller_id')->like(qr/\d+/);

    return
      if ( $self->check_params( $start_date, $end_date, $v ) );

    my @rs = $dbh->resultset('CallRecord')->search(
        {
            caller_id => $caller_id,
            call_date => {
                '>=' => $start_date,
                '<'  => $end_date,
            },
            defined $call_type ? ( type => $call_type ) : ()
        }

    );

    @rs = map {
        {
            caller_id => $_->caller_id,
            recipient => $_->recipient,
            call_date => $_->call_date->ymd,
            end_time  => $_->end_time,
            duration  => $_->duration,
            cost      => $_->cost,
            reference => $_->reference,
            currency  => $_->currency,
            type      => $_->type
        }
    } @rs;

    $self->render( json => \@rs );

}

sub get_most_expensive_calls ($self) {
    my $caller_id  = $self->param('caller_id');
    my $start_date = $self->param('start_date');
    my $end_date   = $self->param('end_date');
    my $call_type  = $self->param('call_type');
    my $n          = $self->param('n');

    my $dbh = $self->app->{dbh};
    my $v   = $self->validation;

    $v->optional('call_type')->in( '1', '2' );
    $v->required('n')->like(qr/\d+/);
    $v->required('start_date')->like(qr/\d{4}\-\d{2}-\d/);
    $v->required('end_date')->like(qr/\d{4}\-\d{2}-\d/);
    $v->required('caller_id')->like(qr/\d+/);

    return
      if ( $self->check_params( $start_date, $end_date, $v ) );

    my @rs = $dbh->resultset('CallRecord')->search(
        {
            caller_id => $caller_id,
            call_date => { '>=' => $start_date, '<' => $end_date },
            currency  => 'GBP',
            defined $call_type ? ( type => $call_type ) : (),
        },
        {
            order_by => { -desc => 'cost' },
            rows     => $n,
        }
    );

    @rs = map {
        {
            caller_id => $_->caller_id,
            recipient => $_->recipient,
            call_date => $_->call_date->ymd,
            end_time  => $_->end_time,
            duration  => $_->duration,
            cost      => $_->cost,
            reference => $_->reference,
            currency  => $_->currency,
            type      => $_->type
        }
    } @rs;

    $self->render( json => \@rs );
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

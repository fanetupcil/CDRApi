package CDRApi::Model::CdrModel;

sub new {
    my ( $class, $dbh ) = @_;
    my $self = bless { dbh => $dbh }, $class;
    return $self;
}

sub get_cdr_by_reference {
    my ( $self, $reference ) = @_;
    my @rs = $self->{dbh}->resultset('CallRecord')
      ->search( { reference => $reference } );

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
    return \@rs;
}

sub get_calls_stats {
    my ( $self, $start_date, $end_date, $call_type ) = @_;

    my $rs = $self->{dbh}->resultset('CallRecord')->search(
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
use Data::Dumper; print Dumper $rs;
    $rs = $rs->next;

    $rs = {
        call_count     => $rs->get_column('call_count'),
        total_duration => $rs->get_column('total_duration') || '0'
    };

    return $rs;
}

sub get_filtered_cdrs {
    my ( $self, $start_date, $end_date, $caller_id, $call_type, $n) = @_;

    my @rs = $self->{dbh}->resultset('CallRecord')->search(
        {   
            caller_id => $caller_id,
            call_date => {
                '>=' => $start_date,
                '<'  => $end_date,
            },
            defined $call_type ? ( type => $call_type ) : (),
            defined $n ? (  currency  => 'GBP') : ()
           
        },
        {
            defined $n
            ? (
                order_by => { -desc => 'cost' },
                rows     => $n
              )
            : ()
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

    return \@rs;
}

1;

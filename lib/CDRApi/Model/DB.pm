package CDRApi::Model::DB;
use lib '/home/stefan/Documents/CDRApi/lib';

use CDRApi::Schema;
use DBIx::Class ();

use strict;

my ($schema_class, $connect_info);

BEGIN {
    $schema_class = 'CDRApi::Schema';
    $connect_info = {
        dsn      => 'dbi:mysql:cdr',
        user     => 'root',
        password => 'root',
    };
}

sub new {
    return __PACKAGE__->config( $schema_class, $connect_info );
}

sub config {
    my $class = shift;

    my $self = {
        schema       => shift,
        connect_info => shift,
    };

    my $dbh = $self->{schema}->connect(
        $self->{connect_info}->{dsn}, 
        $self->{connect_info}->{user}, 
        $self->{connect_info}->{password}
    );

    return $dbh;
}

1;

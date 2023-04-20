package CDRApi::Controller::Data;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::IOLoop;
use Mojo::Promise;

use Text::CSV_XS;

sub upload_and_load ($self) {
    my $upload_dir = $self->app->config->{upload};
    my $file       = $self->req->upload('file');

    return $self->render( text => 'No file uploaded.', status => 400 )
      unless $file;

    my $dbh      = $self->app->{dbh};
    my $filename = $file->filename;
    my $target   = Mojo::File->new( $upload_dir, $filename );

    _save_file_promise( $file->asset, $target )->then(
        sub {
            $self->_insert_data( $target, $dbh );
            json => { message => "File uploaded successfully: $filename" };
        }
    )->catch(
        sub {
            my $err = shift;
            $self->render( text => "File upload failed: $err", status => 500 );
        }
    );

}

sub _insert_data ( $self, $target, $dbh ) {
    my $batch_size = $self->app->config->{batch_size};
    my $subprocess = Mojo::IOLoop::Subprocess->new;
    my $bad_rows   = 0;

    my $callback = sub {
        my ( $subprocess, $err, @results ) = @_;

        if ($err) {
            $self->render(
                json   => { error => "Error importing CSV: $err" },
                status => 500
            );
        }
        else {
            $self->render(
                json => {
                    message  => "CSV Imported ",
                    bad_rows => $results[0]
                }
            );
        }
    };

    $subprocess->run(
        sub {
            my $subprocess = shift;

            # Parse the CSV file
            my $csv = Text::CSV_XS->new( { sep_char => ',' } );
            open my $fh, "<", $target or die "Can't open file: $!";
            my $count = 0;

            my @data;
            $csv->getline($fh);
            while ( my $row = $csv->getline($fh) ) {

                #TODO , Create custom validation class

                $row->[2] =~ s/(\d\d)\/(\d\d)\/(\d{4})/$3-$2-$1/;
                $row->[4] =~ s/[^\d]//g;

                # Store each row in an array
                push @data,
                  {
                    caller_id => $row->[0] || '0',
                    recipient => $row->[1] || '0',
                    call_date => $row->[2],
                    end_time  => $row->[3],
                    duration  => $row->[4] || '0',
                    cost      => $row->[5],
                    reference => $row->[6],
                    currency  => $row->[7],
                    type      => $row->[8]
                  };

                $count++;

                # Insert the data in batches of $batch_size
                if ( $count % $batch_size == 0 ) {

# Insert the data asynchronously and if error in batch try to insert every data row by row
                    eval { $dbh->resultset('CallRecord')->populate( \@data ); };
                    if ($@) {
                        foreach (@data) {
                            eval {
                                $dbh->resultset('CallRecord')->populate($_);
                            };
                            if ($@) {
                                $bad_rows++;
                            }
                        }
                    }
                    @data = ();
                }
            }

            # Insert any remaining data
            if (@data) {

                eval { $dbh->resultset('CallRecord')->populate( \@data ); };
                if ($@) {
                    foreach (@data) {
                        eval { $dbh->resultset('CallRecord')->populate($_); };
                        if ($@) {
                            $bad_rows++;
                        }
                    }
                }
            }
            close $fh;
            return $bad_rows;
        },
        $callback
    );
}

sub _save_file_promise ( $src, $dst ) {

    return Mojo::Promise->new(
        sub ( $resolve, $reject ) {
            Mojo::IOLoop->subprocess(
                sub {
                    $src->move_to($dst);
                },
                sub {
                    my ( $subprocess, $err ) = @_;
                    return $reject->($err) if $err;
                    $resolve->($dst);
                }
            );
        }
    );

    Mojo::IOLoop->next_tick(
        sub {
            Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
        }
    );
}

1;

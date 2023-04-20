use utf8;
package CDRApi::Schema::Result::CallRecord;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDRApi::Schema::Result::CallRecord

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::EncodedColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 TABLE: C<call_records>

=cut

__PACKAGE__->table("call_records");

=head1 ACCESSORS

=head2 caller_id

  data_type: 'bigint'
  is_nullable: 0

=head2 recipient

  data_type: 'bigint'
  is_nullable: 0

=head2 call_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 end_time

  data_type: 'time'
  is_nullable: 1

=head2 duration

  data_type: 'integer'
  is_nullable: 1

=head2 cost

  data_type: 'decimal'
  is_nullable: 1
  size: [10,3]

=head2 reference

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 currency

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 type

  data_type: 'enum'
  extra: {list => [1,2]}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "caller_id",
  { data_type => "bigint", is_nullable => 0 },
  "recipient",
  { data_type => "bigint", is_nullable => 0 },
  "call_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "end_time",
  { data_type => "time", is_nullable => 1 },
  "duration",
  { data_type => "integer", is_nullable => 1 },
  "cost",
  { data_type => "decimal", is_nullable => 1, size => [10, 3] },
  "reference",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "currency",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "type",
  { data_type => "enum", extra => { list => [1, 2] }, is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-04-18 22:10:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zMotHPRB5w13j1zSE3B4lg
__PACKAGE__->set_primary_key('reference');
__PACKAGE__->table('call_records');

#pus dto

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

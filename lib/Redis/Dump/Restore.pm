
package Redis::Dump::Restore;

use Moose;
use MooseX::Types::Path::Class;
use JSON;
with 'MooseX::Getopt';

use Redis 1.904;

# ABSTRACT: It's a simple way to restore data to redis-server based on redis-dump
# VERSION

has _conn => (
    is       => 'ro',
    isa      => 'Redis',
    init_arg => undef,
    lazy     => 1,
    default  => sub { Redis->new( server => shift->server ) }
);

sub _set_string {
    my ( $self, $name, $value ) = @_;
    $self->_conn->set( $name => $value );
}

sub _set_array {
    my ( $self, $name, $value ) = @_;

    foreach my $item ( @{$value} ) {
        my $type = ref($item);
        $self->_conn->rpush( $name, $item ) if !$type;    # list

        if ( $type eq 'HASH' ) {
            my %zsets = %{$item};
            foreach my $range ( keys %zsets ) {
                $self->_conn->zadd( $name, $range, $zsets{$range} );
            }
        }

    }

}

sub _set_hash {
    my ( $self, $name, $value ) = @_;

    my %sets = %{$value};
    foreach my $item ( keys %sets ) {
        my $type = ref($item);
        $self->sadd( $name, $item, $sets{$item} ) if !$type;    # smembers

        if ( $type eq 'HASH' ) {
            my %hashs = %{$item};
            foreach my $key ( keys %hashs ) {
                $self->_conn->hset( $name, $key, $hashs{$key} );
            }
        }
    }
}

sub _set_values_by_keys {
    my $self = shift;

    $self->_conn->flushall if $self->flushall;

    my %keys = %{ from_json( $self->file->slurp ) };
    foreach my $key ( keys %keys ) {
        my $type = ref( $keys{$key} );
        $self->_set_string( $key, $keys{$key} ) if !$type;
        $self->_set_array( $key, $keys{$key} ) if $type eq 'ARRAY';
        $self->_set_hash( $key, $keys{$key} ) if $type eq 'HASH';
    }
    return 1;
}

=head1 SYNOPSIS

    use Redis::Dump::Restore;

    my $restore = Redis::Dump::Restore({ server => '127.0.0.6379', file => 'foo.txt');


=head1 DESCRIPTION

It's a simple way to retore data to redis-server in JSON format or any format
you want.

=head1 COMMAND LINE API

This class uses L<MooseX::Getopt> to provide a command line api. The command line options map to the class attributes.

=head1 METHODS

=head2 new_with_options

Provided by L<MooseX::Getopt>. Parses attributes init args from @ARGV.

=head2 run

Perfomas the actual restore.

=cut

sub run {
    my $self = shift;

    my $fh = $self->file->openr() or confess "Can't read file: $!";

    return $self->_set_values_by_keys;
}

=head1 ATTRIBUTES

=head2 server

Host:Port of redis server, example: 127.0.0.1:6379.

=cut

has server => (
    is            => 'ro',
    isa           => 'Str',
    default       => '127.0.0.1:6379',
    documentation => 'Host:Port of redis server (ex. 127.0.0.1:6379)'
);

=head2 flushall

Remove all keys from all databases

=cut

has flushall => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Remove all keys from all databases'
);

=head2 file

File with dump

=cut

has file => (
    is            => 'ro',
    isa           => 'Path::Class::File',
    coerce        => 1,
    documentation => 'File with restore'
);

1;

__END__

=head1 DEVELOPMENT

Redis::Dump is a open source project for everyone to participate. The code repository
is located on github. Feel free to send a bug report, a pull request, or a
beer.

L<http://www.github.com/maluco/Redis-Dump>

=head1 SEE ALSO

L<Redis::Dump>, L<App::Redis::Dump>, L<App::Redis::Dump::Restore>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Redis::Dump

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Redis-Dump>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Redis-Dump>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Redis-Dump>

=item * Search CPAN

L<http://search.cpan.org/dist/Redis-Dump>

=back

=cut



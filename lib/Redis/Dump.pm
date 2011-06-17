
package Redis::Dump;

use Moose;
with 'MooseX::Getopt';

use Redis 1.904;

# ABSTRACT: It's a simple way to dump and backup data from redis-server
# VERSION

has _conn => (
    is       => 'ro',
    isa      => 'Redis',
    init_arg => undef,
    lazy     => 1,
    default  => sub { Redis->new( server => shift->server ) }
);

sub _get_keys {
    shift->_conn->keys("*");
}

sub _get_type_and_filter {
    my ( $self, $key ) = @_;
    return if $self->has_filter and not $key =~ $self->filter;
    my $type = $self->_conn->type($key);
    return if @{ $self->type } and not grep {/^$type/} @{ $self->type };
    return $type;
}

sub _get_value {
    my ( $self, $key, $type ) = @_;
    return $self->_conn->get($key) if $type eq 'string';
    return $self->_conn->lrange( $key, 0, -1 ) if $type eq 'list';
    return $self->_conn->smembers($key) if $type eq 'set';

    if ( $type eq 'zset' ) {
        my %hash;
        my @zsets = $self->_conn->zrange( $key, 0, -1, 'withscores' );
        for ( my $loop = 0; $loop < scalar(@zsets) / 2; $loop++ ) {
            my $value = $zsets[ $loop * 2 ];
            my $score = $zsets[ ( $loop * 2 ) + 1 ];
            $hash{$score} = $value;
        }
        return [ {%hash} ];
    }

    if ( $type eq 'hash' ) {
        my %hash;
        foreach my $item ( $self->_conn->hkeys($key) ) {
            $hash{$item} = $self->_conn->hget( $key, $item );
        }
        return {%hash};
    }
}

sub _get_values_by_keys {
    my $self = shift;
    my %keys;

    foreach my $key ( $self->_get_keys ) {
        my $type = $self->_get_type_and_filter($key) or next;
        my $show_name = $key;
        $show_name .= " ($type)" if $self->show_type;
        $keys{$show_name} = $self->_get_value( $key, $type );
    }
    return %keys;
}

=head1 SYNOPSIS

    use Redis::Dump;
    use Data::Dumper;

    my $dump = Redis::Dump->new({ server => '127.0.0.6379', filter => 'foo' });

    print Dumper( \$dump->run );


=head1 DESCRIPTION

It's a simple way to dump data from redis-server in JSON format or any format
you want.

=head1 COMMAND LINE API

This class uses L<MooseX::Getopt> to provide a command line api. The command line options map to the class attributes.

=head1 METHODS

=head2 new_with_options

Provided by L<MooseX::Getopt>. Parses attributes init args from @ARGV.

=head2 run

Perfomas the actual dump.

=cut

sub run {
    my $self = shift;

    return $self->_get_values_by_keys;
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

=head2 filter

String to filter keys stored in redis server.

=cut

has filter => (
    is            => 'ro',
    isa           => 'Str',
    default       => '',
    predicate     => 'has_filter',
    documentation => 'String to filter keys stored in redis server'
);

=head2 type

If you want to get just some types of keys.

It can be: lists, sets, hashs, strings, zsets

=cut

has type => (
    is            => 'ro',
    isa           => 'ArrayRef[Str]',
    default       => sub { [] },
    predicate     => 'has_type',
    documentation => 'Show just this type of key',
);

=head2 show_type

If you want to show type with key name.

=cut

has show_type => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 0,
    documentation => 'If you want to show type with key name.'
);

1;

__END__

=head1 DEVELOPMENT

Redis::Dump is a open source project for everyone to participate. The code repository
is located on github. Feel free to send a bug report, a pull request, or a
beer.

L<http://www.github.com/maluco/Redis-Dump>

=head1 SEE ALSO

L<Redis::Dump::Restore>, L<App::Redis::Dump>, L<App::Redis::Dump::Restore>

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



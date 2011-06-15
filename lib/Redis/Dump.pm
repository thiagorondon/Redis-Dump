
package Redis::Dump;

use Moose;
with 'MooseX::Getopt';

use Redis 1.904;

# ABSTRACT: Backup and restore your Redis data to and from JSON.
# VERSION

has _conn => (
    is => 'rw',
    isa => 'Redis',
    init_arg => undef,
    lazy => 1,
    default => sub { Redis->new( server => shift->server ) }
);

sub _get_keys {
    shift->_conn->keys("*");
}

sub _get_values_by_keys {
    my $self = shift;
    my %keys;
    foreach my $key ($self->_get_keys) {
        
        next if $self->has_filter and $key !~ $self->filter;

        my $type = $self->_conn->type($key);
        
        $keys{$key} = $self->_conn->get($key) if $type eq 'string';
        $keys{$key} = $self->_conn->lrange($key, 0, -1) if $type eq 'list';
        $keys{$key} = $self->_conn->smembers($key) if $type eq 'set';
        $keys{$key} = $self->_conn->zrange($key, 0, -1) if $type eq 'zset';

        if ($type eq 'hash') {
            my %hash;
            foreach my $item ($self->_conn->hkeys($key)) {
                $hash{$item} = $self->_conn->hget($key, $item);
            }
            $keys{$key} = { %hash } ;
        }
    }
    return %keys;
}

=head1 SYNOPSIS

    $ redis-dump --server 127.0.0.1:6379 --filter foo
    {
           "foo" : "1",
    }
    
=head1 DESCRIPTION

It's a simple way to dump data from redis-server in JSON format or any format
you want (you can use Redis::Dump class).

=head1 COMMAND LINE API

This class uses L<MooseX::Getopt> to provide a command line api. The command line options map to the class attributes.

=head1 METHODS

=head2 new_with_options

Provided by L<MooseX::Getopt>. Parses attributes init args from @ARGV.

=head2 run

Perfomas the actual dump, and you can use your code as:

    use Redis::Dump;
    use Data::Dumper;

    my $dump = Redis::Dump({ server => '127.0.0.6379', filter => 'foo' });

    print Dumper( \$dump->run );

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
    is => 'rw',
    isa => 'Str',
    default => '127.0.0.1:6379',
    documentation => 'Host:Port of redis server (ex. 127.0.0.1:6379)'
);

=head2 filter

String to filter keys stored in redis server.

=cut

has filter => (
    is => 'rw',
    isa => 'Str',
    default => '',
    predicate => 'has_filter',
    documentation => 'String to filter keys stored in redis server'
);

1;

__END__

=head1 DEVELOPMENT

Redis::Dump is a open source project for everyone to participate. The code repository
is located on github. Feel free to send a bug report, a pull request, or a
beer.

L<http://www.github.com/maluco/Redis-Dump>

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



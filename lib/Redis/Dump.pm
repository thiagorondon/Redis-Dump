
package Redis::Dump;

use Moose;
with 'MooseX::Getopt';

use Redis 1.904;

# ABSTRACT: Backup and restore your Redis data to and from JSON.
# VERSION

has server => (
    is => 'rw',
    isa => 'Str',
    default => '127.0.0.1:6379'
);

has conn => (
    is => 'rw',
    isa => 'Redis',
    lazy => 1,
    default => sub { Redis->new( server => shift->server ) }
);

has filter => (
    is => 'rw',
    isa => 'Str',
    default => '',
    predicate => 'has_filter'
);

sub _get_keys {
    shift->conn->keys("*");
}

sub _get_values_by_keys {
    my $self = shift;
    my %keys;
    foreach my $key ($self->_get_keys) {
        next if $self->has_filter and $key !~ $self->filter;

        my $type = $self->conn->type($key);
        $keys{$key} = $self->conn->get($key) if $type eq 'string';
        $keys{$key} = $self->conn->lrange($key, 0, -1) if $type eq 'list';
        $keys{$key} = $self->conn->smembers($key) if $type eq 'set';
        $keys{$key} = $self->conn->zrange($key, 0, -1) if $type eq 'zset';

        if ($type eq 'hash') {
            my %hash;
            my @hashs = $self->conn->hkeys($key);
            foreach my $item (@hashs) {
                $hash{$item} = $self->conn->hget($key, $item);
            }
            $keys{$key} = { %hash } ;
        }
    }
    return %keys;
}

=head1 DESCRIPTION

Backup and restore your Redis data to and from JSON.


    $ redis-dump --server 127.0.0.1:6379 --filter foo
    {
           "foo" : "1",
    }
     
=head2 run

You can use as a module.

    use Redis::Dump;
    use Data::Dumper;

    my $dump = Redis::Dump({ server => '127.0.0.16379', filter => 'foo' });

    print Dumper( \$dump->run );

=cut

sub run {
    my $self = shift;

    return $self->_get_values_by_keys;
}

1;


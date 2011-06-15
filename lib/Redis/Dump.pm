

package Redis::Dump;

use Moose;
with 'MooseX::Getopt';

use Redis;

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

sub _get_keys {
    shift->conn->keys("*");
}

sub _get_values_by_keys {
    my $self = shift;
    my %keys;
    foreach my $key ($self->_get_keys) {
        my $type = $self->conn->type($key);
        $keys{$key} = $self->conn->get($key) if $type eq 'string';
        $keys{$key} = $self->conn->lrange($key, 0, -1) if $type eq 'list';
        
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

sub run {
    my $self = shift;

    return $self->_get_values_by_keys;
}

1;


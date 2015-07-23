package Device::SerialPort;

use parent 'Test::Device::SerialPort';
use strict;
use warnings;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->mock_port(1);
    return $self;
}

1;

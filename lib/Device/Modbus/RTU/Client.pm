package Device::Modbus::RTU::Client;

use parent 'Device::Modbus::Client';
use Device::Modbus::RTU::ADU;
use Role::Tiny::With;

use Carp;
use strict;
use warnings;
use v5.10;

with 'Device::Modbus::RTU';

sub new {
    my ($class, %args) = @_;

    my $self = bless \%args, $class;
    $self->open_port;
    return $self;    
}

1;

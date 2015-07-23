package Device::Modbus::RTU::ADU;

use parent 'Device::Modbus::ADU';
use Carp;
use strict;
use warnings;
use v5.10;

sub crc {
    my ($self, $crc) = @_;
    if (defined $crc) {
        $self->{crc} = $crc;
    }
    croak "CRC has not been declared"
        unless exists $self->{crc};
    return $self->{crc};
}

1;

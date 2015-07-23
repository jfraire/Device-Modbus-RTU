package Device::Modbus::RTU::Client;

use parent 'Device::Modbus::Client';
use Role::Tiny::With;
use Device::Modbus::RTU::ADU;
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

### Build the Application Data Unit

sub build_adu {
    my ($self, $request) = @_;
    croak "Please include a unit number in the request."
        unless exists $request->{unit} && $request->{unit};
    my $header = $self->build_header($request);
    my $pdu    = $request->pdu();
    my $footer = $self->build_footer($header, $pdu);
    return $header . $pdu . $footer;
}

sub build_header {
    my ($self, $request) = @_;
    my $header = pack 'C', $request->{unit};
    return $header;
}

sub build_footer {
    my ($self, $header, $pdu) = @_;
    return $self->crc_for($header . $pdu);
}

# Taken from MBClient (and verified against Modbus docs)
sub crc_for {
    my ($self, $str) = @_;
    my $crc = 0xFFFF;
    my ($chr, $lsb);
    for my $i (0..length($str)-1) {
        $chr  = ord(substr($str, $i, 1));
        $crc ^= $chr;
        for (1..8) {
            $lsb = $crc & 1;
            $crc >>= 1;
            $crc ^= 0xA001	if $lsb;
        }
	}
    return pack 'v', $crc;
}

### Parsing a response

sub new_adu {
    my $self = shift;
    return Device::Modbus::RTU::ADU->new();
}

sub parse_header {
    my ($self, $adu) = @_;
    my $unit = $self->read_port(1, 'C');
    $adu->unit($unit);
    return $adu;
}

sub parse_footer {
    my ($self, $adu) = @_;
    my $crc = $self->read_port(2, 'v');
    $adu->crc($crc);
    return $adu;
}

1;

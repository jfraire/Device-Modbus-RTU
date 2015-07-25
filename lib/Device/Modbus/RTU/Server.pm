package Device::Modbus::RTU::Server;

use parent 'Device::Modbus::Server';
use Device::Modbus::RTU::ADU;
use Try::Tiny;
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

sub start {
    while (1) {
        my $adu;
        try {
            $req_adu = $server->receive_request;
        }
        catch {
            # We should have an exception object
            if (ref $_ && ref $_ eq 'Device::Modbus::Exception') {
                $req_adu = $_;
            }
        }

        # Ignore if the unit doesn't match or if it doesn't exist
        next unless defined $req_adu->unit
            && exists $self->units->{$req_adu->unit};

        # Process if the unit matches
        my $resp_adu = $self->new_adu;
        $resp_adu->unit($adu->unit);
        
        my $resp = $self->modbus_server($resp_adu);
        my $msg  = $self->build_adu($resp_adu);

        # And send the response!
        $self->write_port($resp_adu);
    }
}

1;

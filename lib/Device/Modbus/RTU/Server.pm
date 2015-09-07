package Device::Modbus::RTU::Server;

use parent 'Device::Modbus::Server';
use Try::Tiny;
use Role::Tiny::With;

use Carp;
use strict;
use warnings;
use v5.10;

with 'Device::Modbus::RTU';

sub new {
    my ($class, %args) = @_;

    my $self = $class->proto(%args);

    $SIG{INT} = sub {
        $self->log(2, 'Server is shutting down');
        $self->exit;
    };
    
    return $self;    
}

sub receive_request {
    my $self = shift;
    my $adu;
    do {
        $adu = $self->new_adu();
        $self->parse_header($adu);
        next unless $adu->unit;
    }
    until (exists $self->units->{$adu->unit});

    $self->parse_pdu($adu);
    $self->parse_footer($adu);
    return $adu;
}

sub start {
    my $self = shift;

    $self->log(2, 'Starting server');
    $self->open_port;
    $self->{running} = 1;

    while ($self->{running}) {
        my $req_adu;
        my $error = 0;
        try {
            $req_adu = $self->receive_request;
            $self->log(4, 'Received a request');
        }
        catch {
            $self->log(2, "Exception while waiting for requests: $_");
            $error = 1;
        };
        next if $error;

        # If it is an exception object, we're done
        if ($req_adu->message->isa('Device::Modbus::Exception')) {
            $self->write_port($req_adu);
            next;
        }

        # Process request
        if (!$error) {
            my $resp = $self->modbus_server($req_adu);
            my $resp_adu = $self->new_adu($resp);
            $resp_adu->unit($req_adu->unit);
        
            # And send the response!
            $self->write_port($resp_adu);
        }
    }

    $self->disconnect;
    $self->log(2, 'Server is down: Port is closed');
}

sub exit {
    my $self = shift;
    $self->{running} = 0;
}

1;

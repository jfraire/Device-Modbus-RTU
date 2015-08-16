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
    $self->open_port;
    return $self;    
}

sub parse_header {
    my ($self, $adu) = @_;
    my $unit = $self->read_port(1, 'C');
    unless (exists $self->units->{$unit}) {
        die "Request for a non-supported unit ($unit)\n";
    }
    $adu->unit($unit);
    return $adu;
}

sub start {
    my $self = shift;

    $self->log(2, 'Starting server');
    
    while (1) {

        # This part will see also requests for other units, and their
        # responses... would it be necessary to parse *their*
        # responses also?
        my $req_adu;
        try {
            $req_adu = $self->receive_request;
            $self->log(4, 'Received a request');
        }
        catch {
            # We should have an exception object
            if (ref $_ && ref $_ eq 'Device::Modbus::Exception') {
                $self->log(2, "Request resulted in exception: $_");
                $req_adu = $_;
            }
            elsif (/^Request for non-supported unit/) {
                $self->log(4, "Ignoring: $_");
                $self->ignore_port;
            }
            else {
                $self->log(2, "Error receiving request: $_");
            }
        };

            # Ignore if the unit doesn't match or if it doesn't exist
        next unless defined $req_adu && defined $req_adu->unit
            && exists $self->units->{$req_adu->unit};

        # If it is an exception object, we're done
        if ($req_adu->isa('Device::Modbus::Exception')) {
            $self->write_port($req_adu);
            next;
        }

        # Process request
        my $resp = $self->modbus_server($req_adu);
        my $resp_adu = $self->new_adu($resp);
        $resp_adu->unit($req_adu->unit);
        
        # And send the response!
        $self->write_port($resp_adu);
    }
}

1;

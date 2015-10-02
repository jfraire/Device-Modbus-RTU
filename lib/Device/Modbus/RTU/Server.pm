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

# Simply ignore requests for other units
sub request_for_others {
    return;
}

sub start {
    my $self = shift;

    $self->log(2, 'Starting server');
    $self->open_port;
    $self->{running} = 1;

    while ($self->{running}) {
        my $req_adu;
        my $redo = 0;
        try {
            $req_adu = $self->receive_request;
            $self->log(4, 'Received a request');
            $self->log(4, "> $req");
        }
        catch {
            $redo++;
            unless ($_ =~ /^Timeout/) {
                $self->log(2, "Error while receiving a request: $_");
            }
        };
        next if $redo;

        # If it is an exception object, we're done
        if ($req_adu->message->isa('Device::Modbus::Exception')) {
            $self->log(3, "Exception while waiting for requests: $_");
            $self->write_port($req_adu);
            next;
        }

        # Process request
        my $resp = $self->modbus_server($req_adu);
        my $resp_adu = $self->new_adu($resp);
        $resp_adu->unit($req_adu->unit);
        $self->log(4, "< Response: $resp_adu");
    
        # And send the response!
        $self->write_port($resp_adu);
    }

    $self->disconnect;
    $self->log(2, 'Server is down: Port is closed');
}

sub exit {
    my $self = shift;
    $self->{running} = 0;
}

# Logger routine. It will simply print messages on STDERR.
# It accepts a logging level and a message. If the level is equal
# or less than $self->log_level, the message is processed.
# To avoid unnecessary processing, messages that require processing can
# be sent in the form of a code reference to minimize performance hits.
# It will add a stringified level, the localtime string
# and caller information.
# It conforms to the interface provided by Net::Server; the subroutine
# idea comes from Log::Log4Perl
my %level_str = (
    0 => 'ERROR',
    1 => 'WARNING',
    2 => 'NOTICE',
    3 => 'INFO',
    4 => 'DEBUG',
);

sub log_level {
    my ($self, $level) = @_;
    if (defined $level) {
        $self->{log_level} = $level;
    }
    return $self->{log_level};
}

sub log {
    my ($self, $level, $msg) = @_;
    return unless $level <= $self->log_level;
    my $time = localtime();
    my ($package, $filename, $line) = caller;

    my $message = ref $msg ? $msg->() : $msg;
    
    print STDOUT
        "$level_str{$level} : $time -- $0 -- $package -- $message\n";
    return 1;
}

1;

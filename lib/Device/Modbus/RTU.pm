package Device::Modbus::RTU;

use Device::SerialPort;
use Carp;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.020';

use Role::Tiny;

sub open_port {
    my $self = shift;

    # Validate parameters
    croak "Attribute 'port' is required for a Modbus RTU client"
        unless exists $self->{port};

    # Defaults related with the serial port
    $self->{baudrate} //=   9600;
    $self->{databits} //=      8;
    $self->{parity}   //= 'even';
    $self->{stopbits} //=      1;
    $self->{timeout}  //=     10;  # seconds

    # Serial Port object
    my $serial = Device::SerialPort->new($self->{port});
    croak "Unable to open serial port " . $self->{port} unless $serial;

    $serial->baudrate ($self->{baudrate});
    $serial->databits ($self->{databits});
    $serial->parity   ($self->{parity});
    $serial->stopbits ($self->{stopbits});
    $serial->handshake('none');

    # char_time and read_char_time are given in milliseconds
    $self->{char_time} =
        1000*($self->{databits}+$self->{stopbits}+1)/ $self->{baudrate};

    $serial->read_char_time($self->{char_time});
    if ($self->{baudrate} < 19200) { 
        $serial->read_const_time(3.5 * $self->{char_time});
    }
    else {
        $serial->read_const_time(1.75);
    }

    $serial->write_settings || croak "Unable to open port: $!";
    $serial->purge_all;
    $SIG{INT} = sub { $serial->close; die "Good bye\n"; };
    $self->{port} = $serial;
    return $serial;
}

sub read_port {
    my ($self, $bytes_qty, $pattern) = @_;

    my $timeout = 1000 * $self->{timeout};
    my $message = '';
    while ($timeout > 0) {
        my ($bytes, $read) = $self->{port}->read($bytes_qty);
        if ($bytes) {
            $message .= $read;
        }
        
        last if length($message) == $bytes_qty; 

        $timeout -= $self->{port}->read_const_time + $bytes * $self->{char_time};
    }
    croak 'Timeout reading from port' unless $timeout > 0;
    return unpack $pattern, $message;
}


sub write_port {
    my ($self, $message) = @_;
    $self->{port}->write($message);
}

sub disconnect {
    my $self = shift;
    $self->{port}->close;
}

1;

__END__

=head1 NAME

Device::Modbus::RTU - Perl distribution to implement Modbus RTU communications

=head1 DESCRIPTION

This distribution implements the Modbus RTU protocol on top of Device::Modbus.

=head1 SEE ALSO

=head2 Other distributions

These are other implementations of Modbus in Perl which may be well suited for your application:
L<Protocol::Modbus>, L<MBclient>, L<mbserverd|https://github.com/sourceperl/mbserverd>.

=head1 GITHUB REPOSITORY

You can find the repository of this distribution in L<GitHub|https://github.com/jfraire/Device-Modbus>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

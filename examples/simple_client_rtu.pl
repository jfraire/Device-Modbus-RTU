#! /usr/bin/env perl

use Device::Modbus;
use Device::Modbus::RTU::Client;
use Data::Dumper;
use strict;
use warnings;
use v5.10;

my $client = Device::Modbus::RTU::Client->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'none',
);

my $req = $client->read_holding_registers(
    address  => 2,
    quantity => 1,
    unit     => 3
);

say "->" . Dumper $req;

while (1) {
    $client->send_request($req);
    my $resp = $client->receive_response;
    say "<-" . Dumper $resp;
    sleep 1;
}

#! /usr/bin/env perl

use lib 't/lib', '../../Test-Device-SerialPort/lib';
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok 'Device::Modbus::RTU::Client';
}

my $client = Device::Modbus::RTU::Client->new( port => 'test' );
isa_ok $client->{port}, 'Test::Device::SerialPort';

my @responses = (
    '060103cd6b05',              # Read coils, 24 values, unit 0x06
    '140203acdb35',              # Read discrete inputs, 24 values, unit 0x16
    '030306022b00000064',        # Read holding registers, 3 values, unit 0x03
);

my @adus;
foreach my $resp (@responses) {
    my $pdu = pack 'H*', $resp;
    my $crc = Device::Modbus::RTU::Client->crc_for($pdu);
    push @adus, $pdu . $crc;
}

$client->{port}->mock_messages(@adus);

{
    my $adu = $client->receive_response;
    ok $adu->success,                    'Parsed ADU without error';
    is $adu->unit, 0x06,                 'Unit value retrieved is 0x06';
    is $adu->function, 'Read Coils',     'Function is 0x01';
    is_deeply [$adu->values], [0,0,1,1,0,1,0,1, 1,1,0,1,1,0,1,1, 1,0,1,0,1,1,0,0],
        'Values retrieved correctly';
}

done_testing();


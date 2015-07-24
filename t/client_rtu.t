#! /usr/bin/env perl

use lib 't/lib';
use Test::More tests => 13;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::RTU::Client';
}

### Tests for generating a request

{
    my $request = Device::Modbus::RTU::Client->read_coils(
        unit     =>  3,
        address  => 19,
        quantity => 19
    );

    isa_ok $request, 'Device::Modbus::Request';

    my $header = Device::Modbus::RTU::Client->build_header($request);
    is ord($header), 3,
        'The header of the Modbus message is the unit number';

    my $footer = Device::Modbus::RTU::Client->build_footer(chr(2),chr(7));
    is_deeply [unpack 'CC', $footer], [0x41,0x12],
        'CRC is according to the example in Modbus specification';

    my $adu = Device::Modbus::RTU::Client->build_adu($request);
    my $pdu_string = unpack 'H*', $adu;
    is $pdu_string, '0301001300138de0',
        'PDU for Read Coils function is as expected';
}

{
    my $footer = Device::Modbus::RTU::Client->build_footer(pack('H*', '010402FFFF'), '');
    is_deeply [unpack 'CC', $footer], [0xB8, 0x80],
        'CRC is according to the example in Wikipedia';
}

{
    # Croaks if units are not defined
    my $req = Device::Modbus::RTU::Client->read_coils(
        address  => 19,
        quantity => 19
    );

    eval {
        my $adu = Device::Modbus::RTU::Client->build_adu($req);
    };
    like $@, qr/unit number/,
        'Clients cannot write an ADU without unit number';
}

{
    # Croaks if units are not defined
    my $req = Device::Modbus::RTU::Client->read_coils(
        unit     => 0,
        address  => 19,
        quantity => 19
    );

    eval {
        my $adu = Device::Modbus::RTU::Client->build_adu($req);
    };
    like $@, qr/unit number/,
        'Clients cannot write an ADU for unit zero';
}

##### Parsing a response
my $client = Device::Modbus::RTU::Client->new( port => 'test' );
isa_ok $client->{port}, 'Test::Device::SerialPort';

{
    my $response = '0103cd6b05';          # Read coils
    my $pdu = pack 'H*', "06$response";   # Unit 6
    my $crc = Device::Modbus::RTU::Client->crc_for($pdu);
    my $adu = $pdu . $crc;
    $client->{port}->mock_messages($adu);
    my $resp_adu = $client->receive_response;
    ok $resp_adu->success,                    'Parsed ADU without error';
    is $resp_adu->unit, 0x06,                 'Unit value retrieved is 0x06';
    is $resp_adu->function, 'Read Coils',     'Function is 0x01';
    is_deeply $resp_adu->values, [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0,0,0,0,0],
        'Values retrieved correctly';
}


done_testing();
 

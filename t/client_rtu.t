#! /usr/bin/env perl

use Test::More tests => 7;
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

done_testing();
 

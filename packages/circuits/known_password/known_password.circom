pragma circom 2.0.3;

include "../circomlib/circuits/sha256/sha256.circom";
include "../circomlib/circuits/bitify.circom";

/**
 * @param N max length of password in bytes
 */
template Main(N) {
    signal input player;
    signal input password[N];
    signal output out;

    component byte_to_bits[N];
    for (var i = 0; i < N; i++) {
        byte_to_bits[i] = Num2Bits(8);
        byte_to_bits[i].in <== password[i];
    }

    component sha256 = Sha256(N*8);
    for (var i = 0; i < N; i++) {
        for (var j = 0; j < 8; j++) {
            sha256.in[i*8+j] <== byte_to_bits[i].out[7-j];
        }
    }
    
    component bits_to_num = Bits2Num(256);
    for (var i = 0; i < 256; i++) {
        bits_to_num.in[i] <== sha256.out[255-i];
    }
    out <== bits_to_num.out;
}

component main {public [player]} = Main(10);
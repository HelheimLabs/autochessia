pragma circom 2.0.3;

include "../circomlib/circuits/sha256/sha256.circom";
include "../circomlib/circuits/bitify.circom";

/**
 * @param N max length of password in bytes
 */
template Main(N) {
    signal input player;
    signal input password[N];
    signal output hash_part1;
    signal output hash_part2;

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

    // we cannot directly convert the hash result to an uint256
    // because it's probably larger than the prime number, where 
    // p = 21888242871839275222246405745257275088548364400416034343698204186575808495617.
    
    component bits_to_num1 = Bits2Num(128);
    for (var i = 0; i < 128; i++) {
        bits_to_num1.in[i] <== sha256.out[127-i];
    }
    component bits_to_num2 = Bits2Num(128);
    for (var i = 0; i < 128; i++) {
        bits_to_num2.in[i] <== sha256.out[255-i];
    }
    hash_part1 <== bits_to_num1.out;
    hash_part2 <== bits_to_num2.out;
}

component main {public [player]} = Main(10);
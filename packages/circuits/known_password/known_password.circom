pragma circom 2.0.3;

include "../sha256_bytes/sha256_bytes.circom";

/**
 * @param N max length of password in bytes
 */
template Main(N) {
    signal input player[20];
    signal input hash[32];
    signal input password[N];
    // signal output out[32];

    component sha256 = Sha256Bytes(N);
    sha256.in <== password;
    // out <== sha256.out;

    for (var i = 0; i < 32; i++) {
        sha256.out[i] === hash[i];
    }
}

component main {public [player,hash]} = Main(10);
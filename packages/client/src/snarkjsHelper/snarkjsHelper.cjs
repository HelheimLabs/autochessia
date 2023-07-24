const snarkjs = require("snarkjs");
const fs = require("fs");

async function generatePwProof(_player, _password) {
    const { proof, publicSignals } = await snarkjs.groth16.fullProve({player: _player, password: _password}, "known_password.wasm", "pw_0001.zkey");

    console.log("Proof: ");
    console.log(JSON.stringify(proof, null, 1));

    console.log("Public signals: ");
    console.log(JSON.stringify(publicSignals, null, 1));

    const vKey = JSON.parse(fs.readFileSync("verification_key.json"));

    const res = await snarkjs.groth16.verify(vKey, publicSignals, proof);

    if (res === true) {
        console.log("Verification OK");
    } else {
        console.log("Invalid proof");
    }
    
    return proof;
}

generatePwProof(10, [0,0,0,0,0,0,0,0,0,0]).then(() => {
    process.exit(0);
});
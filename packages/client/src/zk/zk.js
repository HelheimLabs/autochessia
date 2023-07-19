const { exportCallDataGroth16 } = require("./snarkjsZkproof");

let inputs={
  "player": ["0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","1"],
  "password": ["0","0","0","0","0","0","0","0","0","0"],
  "hash": ["1","212","72","175","217","40","6","84","88","207","103","11","96","245","165","148","215","53","175","1","114","200","214","127","34","168","22","128","19","38","129","202"]
}

export async function Create() {

  let dataResult = await exportCallDataGroth16(
      inputs,
      "./zkproof/circuit.wasm",
      "./zkproof/circuit_final.zkey"
  );

  console.log(dataResult)

  return dataResult

}


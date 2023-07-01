// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Creatures, GameConfig } from "../src/codegen/Tables.sol";
import { Board } from "../src/codegen/Tables.sol";
import { Piece } from "../src/codegen/Tables.sol";
import { BoardStatus } from "../src/codegen/Types.sol";

contract PostDeploy is Script {
  function run(address worldAddress) external {
    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // ------------------ EXAMPLES ------------------

    // Call increment on the world via the registered function selector
    uint32 newValue = IWorld(worldAddress).increment();
    console.log("Increment via IWorld:", newValue);

    // Setup creatures, gameconfig, pieces and board
    Creatures.set(
      IWorld(worldAddress),
      bytes32(uint256(1)),
      20, // health
      5,  // attack
      1,  // range
      2,  // defense
      5   // speed
    );
    Creatures.set(
      IWorld(worldAddress),
      bytes32(uint256(2)),
      30, // health
      4,  // attack
      1,  // range
      2,  // defense
      4   // speed
    );
    Piece.set(
      IWorld(worldAddress),
      bytes32(uint256(1)),
      bytes32(uint256(1)), // creature id
      1,  // owner
      20, // cur health
      7,  // x
      7   // y
    );
    Piece.set(
      IWorld(worldAddress),
      bytes32(uint256(2)),
      bytes32(uint256(2)), // creature id
      2,  // owner
      30, // cur health
      0,  // x
      0   // y
    );
    bytes32[] memory pieces = new bytes32[](2);
    pieces[0] = bytes32(uint256(1));
    pieces[1] = bytes32(uint256(2));
    Board.set(
      IWorld(worldAddress),
      bytes32(uint256(1)),
      address(uint160(1)),
      address(uint160(2)),
      BoardStatus.INBATTLE,
      0, // round
      0, // turn
      0, // lastwinner
      pieces
    );
    GameConfig.set(
      IWorld(worldAddress),
      1, // board index
      2, // creature index
      8, // length
      8  // width
    );

    vm.stopBroadcast();
  }
}

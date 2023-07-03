// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Creatures, GameConfig } from "../src/codegen/Tables.sol";
import { Player, Game, Board } from "../src/codegen/Tables.sol";
import { Piece, PieceInBattle } from "../src/codegen/Tables.sol";
import { PlayerStatus, GameStatus, BoardStatus } from "../src/codegen/Types.sol";
import { CreatureInitializer } from "./CreatureInitializer.sol";
import { GameConfigInitializer } from "./GameConfigInitializer.sol";

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

    CreatureInitializer.init(IWorld(worldAddress));

    // Setup creatures, gameconfig, pieces and board
    Piece.set(
      IWorld(worldAddress),
      bytes32(uint256(1)),
      0, // creature id
      0,  // tier
      0,  // x
      0   // y
    );
    Piece.set(
      IWorld(worldAddress),
      bytes32(uint256(2)),
      1, // creature id
      0,  // tier
      0,  // x
      0   // y
    );
    PieceInBattle.set(
      IWorld(worldAddress),
      bytes32(uint256(1)),
      bytes32(uint256(1)), // piece id
      650, // cur health
      0,  // x
      0   // y
    );
    PieceInBattle.set(
      IWorld(worldAddress),
      bytes32(uint256(2)),
      bytes32(uint256(1)), // piece id
      650, // cur health
      7,  // x
      0   // y
    );
    PieceInBattle.set(
      IWorld(worldAddress),
      bytes32(uint256(3)),
      bytes32(uint256(2)), // piece id
      520, // cur health
      0,  // x
      0   // y
    );
    PieceInBattle.set(
      IWorld(worldAddress),
      bytes32(uint256(4)),
      bytes32(uint256(2)), // piece id
      520, // cur health
      7,  // x
      0   // y
    );
    bytes32[] memory pieces1 = new bytes32[](1);
    bytes32[] memory pieces2 = new bytes32[](1);
    bytes32[] memory pieces3 = new bytes32[](1);
    bytes32[] memory pieces4 = new bytes32[](1);
    pieces1[0] = bytes32(uint256(1));
    pieces2[0] = bytes32(uint256(2));
    pieces3[0] = bytes32(uint256(3));
    pieces4[0] = bytes32(uint256(4));
    // hack board. todo remove
    Board.set(
      IWorld(worldAddress),
      address(1),
      address(2),
      BoardStatus.UNINITIATED,
      0, // turn
      pieces1,
      pieces4
    );
    
    GameConfigInitializer.init(IWorld(worldAddress));

    vm.stopBroadcast();
  }
}

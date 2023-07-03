// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Creatures, GameConfig } from "../src/codegen/Tables.sol";
import { Player, Game, Board } from "../src/codegen/Tables.sol";
import { Piece, PieceInBattle } from "../src/codegen/Tables.sol";
import { PlayerStatus, GameStatus, BoardStatus } from "../src/codegen/Types.sol";

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
      1,  // index
      20, // health
      5,  // attack
      1,  // range
      2,  // defense
      5,  // speed
      1,  // movement
      "aa"// uri
    );
    Creatures.set(
      IWorld(worldAddress),
      2,  // index
      30, // health
      4,  // attack
      1,  // range
      2,  // defense
      4,  // speed
      1,  // movement
      "bb"//uri
    );
    Piece.set(
      IWorld(worldAddress),
      bytes32(uint256(1)),
      1, // creature id
      0,  // tier
      0,  // x
      0   // y
    );
    Piece.set(
      IWorld(worldAddress),
      bytes32(uint256(2)),
      2, // creature id
      0,  // tier
      0,  // x
      0   // y
    );
    PieceInBattle.set(
      IWorld(worldAddress),
      bytes32(uint256(1)),
      bytes32(uint256(1)), // piece id
      20, // cur health
      0,  // x
      0   // y
    );
    PieceInBattle.set(
      IWorld(worldAddress),
      bytes32(uint256(2)),
      bytes32(uint256(1)), // piece id
      20, // cur health
      7,  // x
      0   // y
    );
    PieceInBattle.set(
      IWorld(worldAddress),
      bytes32(uint256(3)),
      bytes32(uint256(2)), // piece id
      30, // cur health
      0,  // x
      0   // y
    );
    PieceInBattle.set(
      IWorld(worldAddress),
      bytes32(uint256(4)),
      bytes32(uint256(2)), // piece id
      30, // cur health
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
    Board.set(
      IWorld(worldAddress),
      address(1),
      address(2),
      BoardStatus.UNINITIATED,
      0, // turn
      pieces1,
      pieces4
    );
    Player.set(
      IWorld(worldAddress),
      address(1),
      1, // game id
      PlayerStatus.INGAME,
      100, // helath
      0, // streak count
      0, // coin
      0, // tier
      0, // exp
      pieces1,
      new uint64[](0),
      new uint64[](0)
    );
    Player.set(
      IWorld(worldAddress),
      address(2),
      1, // game id
      PlayerStatus.INGAME,
      100, // helath
      0, // streak count
      0, // coin
      0, // tier
      0, // exp
      pieces2,
      new uint64[](0),
      new uint64[](0)
    );
    Game.set(
      IWorld(worldAddress),
      1,
      address(uint160(1)),
      address(uint160(2)),
      GameStatus.INBATTLE,
      0, // round
      0, // finished board
      0  // winner
    );
    GameConfig.set(
      IWorld(worldAddress),
      1, // board index
      2, // creature index
      4, // length
      8, // width
      0, // revenue
      0, // revenueGrowthPeriod
      0,  // inventory slot num
      new uint8[](0) //expUpgrade
    );

    vm.stopBroadcast();
  }
}

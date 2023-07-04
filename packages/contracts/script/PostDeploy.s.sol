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
import { ConfigInitializer } from "./ConfigInitializer.sol";

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
    
    ConfigInitializer.initGameConfig(IWorld(worldAddress));
    ConfigInitializer.initShopConfig(IWorld(worldAddress));
    ConfigInitializer.initCreatureConfig(IWorld(worldAddress));

    vm.stopBroadcast();
  }
}

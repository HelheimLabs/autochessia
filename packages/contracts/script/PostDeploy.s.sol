// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {Creature, GameConfig} from "../src/codegen/index.sol";
import {Player, Game, Board} from "../src/codegen/index.sol";
import {Hero, Piece} from "../src/codegen/index.sol";
import {PlayerStatus, GameStatus, BoardStatus} from "src/codegen/common.sol";
import {CreatureInitializer} from "./CreatureInitializer.sol";
import {ConfigInitializer} from "./ConfigInitializer.sol";
import {EffectInitializer} from "./EffectInitializer.sol";
import {ZkVerifier} from "../src/codegen/index.sol";
import {Groth16Verifier} from "../src/zkVerifier/Verifier.sol";

import {StoreSwitch} from "@latticexyz/store/src/StoreSwitch.sol";

contract PostDeploy is Script {
    function run(address worldAddress) external {
        StoreSwitch.setStoreAddress(worldAddress);
        // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions from the deployer account
        vm.startBroadcast(deployerPrivateKey);

        // ------------------ EXAMPLES ------------------

        Groth16Verifier verifier = new Groth16Verifier();
        ZkVerifier.set(address(verifier));

        ConfigInitializer.initGameConfig(IWorld(worldAddress));

        ConfigInitializer.initShopConfig(IWorld(worldAddress));

        CreatureInitializer.init(IWorld(worldAddress));

        EffectInitializer.init(IWorld(worldAddress));

        // // hack
        // Game.set(IWorld(worldAddress), 666, address(123), address(456), GameStatus.INBATTLE, 1, 0, 0, 0, 1);
        // Hero.set(IWorld(worldAddress), "1", 5, 0, 0, 3);
        // Hero.set(IWorld(worldAddress), "2", 5, 0, 0, 4);
        // Hero.set(IWorld(worldAddress), "3", 2, 0, 3, 4);
        // Hero.set(IWorld(worldAddress), "4", 3, 0, 0, 4);
        // bytes32[] memory ids = new bytes32[](2);
        // ids[0] = "1";
        // ids[1] = "2";
        // Player.set(IWorld(worldAddress), address(123), bytes32(0), 1, PlayerStatus.INGAME, 100, 0, 0, 0, 0, ids, new uint64[](0), new uint64[](0));
        // ids[0] = "3";
        // ids[1] = "4";
        // Player.set(IWorld(worldAddress), address(456), bytes32(0), 1, PlayerStatus.INGAME, 100, 0, 0, 0, 0, ids, new uint64[](0), new uint64[](0));

        // Piece.set(IWorld(worldAddress), "1", "1", 500, 0, 3);
        // Piece.set(IWorld(worldAddress), "2", "2", 500, 0, 4);
        // Piece.set(IWorld(worldAddress), "3", "3", 500, 2, 4);
        // Piece.set(IWorld(worldAddress), "4", "4", 500, 6, 5);
        // ids[0] = "1";
        // ids[1] = "2";
        // bytes32[] memory idss = new bytes32[](2);
        // idss[0] = "3";
        // idss[1] = "4";
        // Board.set(IWorld(worldAddress), address(123), address(456), BoardStatus.INBATTLE, 1, ids, idss);

        vm.stopBroadcast();
    }
}

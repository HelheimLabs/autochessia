// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {MudTest} from "@latticexyz/store/src/MudTest.sol";
import {Creature, CreatureData, GameConfig, Board, Player, ShopConfig} from "../src/codegen/Tables.sol";
import {GameRecord, Game, GameData} from "../src/codegen/Tables.sol";
import {Hero, HeroData} from "../src/codegen/Tables.sol";
import {Piece, PieceData} from "../src/codegen/Tables.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {GameStatus} from "../src/codegen/Types.sol";

contract PveTest is MudTest {
    IWorld public world;

    function setUp() public override {
        super.setUp();
        world = IWorld(worldAddress);
    }

    // function testSinglePlay() public {
    //     vm.startPrank(address(1));
    //     world.singlePlay();
    //     vm.stopPrank();
    // }

    function testSingleTick() public {
        vm.startPrank(address(1));
        world.singlePlay();

        for (uint256 index = 0; index < 30; index++) {
            vm.warp(block.timestamp + 10 seconds);
            world.tick(0, address(1));
        }

        vm.stopPrank();
    }
}

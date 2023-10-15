// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {MudTest} from "@latticexyz/world/test/MudTest.t.sol";
import {Creature, CreatureData, GameConfig, Player, ShopConfig} from "../src/codegen/index.sol";
import {GameRecord, Game, GameData} from "../src/codegen/index.sol";
import {Hero, HeroData} from "../src/codegen/index.sol";
import {Piece, PieceData} from "../src/codegen/index.sol";
import {Board} from "../src/codegen/index.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {GameStatus} from "src/codegen/common.sol";
import {Utils} from "../src/library/Utils.sol";

import {TestCommon} from "./TestCommon.t.sol";

contract AutoBattleSystemTest is MudTest {
    IWorld public world;

    function setUp() public override {
        super.setUp();
        world = IWorld(worldAddress);
        TestCommon.normalStart(vm, world);
    }

    function testMerge() public {
        // set price for refreshing hero to 0
        TestCommon.setRefreshPrice(vm, world, 0);
        // fund 10 coin
        TestCommon.setPlayerCoin(vm, world, address(1), 10);
        // set player tier to 3
        TestCommon.setPlayerTier(vm, world, address(1), 3);
        // set the first hero to 2 in case of affecting merge test
        TestCommon.setHero(vm, world, Player.getItemHeroes(world, address(1), 0), 2, 0, 0);

        vm.startPrank(address(1));
        uint256 num;
        uint8 slotNum = ShopConfig.getSlotNum(world, 0);
        while (num < 3) {
            world.buyRefreshHero();
            for (uint256 i; i < slotNum; ++i) {
                uint64 hero = Player.getItemHeroAltar(world, address(1), i);
                if (hero == 1) {
                    world.buyHero(i);
                    console.log("hero num on board %d", Player.lengthHeroes(world, address(1)));
                    ++num;
                    if (num == 1) {
                        world.placeToBoard(0, 1, uint32(2 + num));
                    }
                    break;
                }
            }
        }
        vm.stopPrank();
        assertEq(1, Utils.getHeroTier(Player.getItemInventory(world, address(1), 0)));
    }

    function testAutoBattle() public {
        // immediate call to autoBattle will revert with reason "preparing time"
        vm.expectRevert("preparing time");
        world.tick(0, address(1));

        // set block.timestamp to current+100s would make it success
        vm.warp(block.timestamp + 100);
        world.tick(0, address(1));
        console.log("ally piece id %d", uint256(Board.getItemPieces(world, address(1), 0)));
        console.log("enemy piece id %d", uint256(Board.getItemEnemyPieces(world, address(1), 0)));
        PieceData memory piece = Piece.get(world, bytes32(uint256(1)));
        console.log("piece 1 cur health %d, x %d, y %d", piece.health, piece.x, piece.y);
        piece = Piece.get(world, bytes32(uint256(3)));
        console.log("piece 3 cur health %d, x %d, y %d", piece.health, piece.x, piece.y);

        world.tick(0, address(1));
        piece = Piece.get(world, bytes32(uint256(1)));
        console.log("piece 1 cur health %d, x %d, y %d", piece.health, piece.x, piece.y);
        piece = Piece.get(world, bytes32(uint256(3)));
        console.log("piece 3 cur health %d, x %d, y %d", piece.health, piece.x, piece.y);
    }
}

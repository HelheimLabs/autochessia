// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {MudTest} from "@latticexyz/store/src/MudTest.sol";
import {Creature, CreatureData, GameConfig, Player, ShopConfig} from "../src/codegen/Tables.sol";
import {GameRecord, Game, GameData} from "../src/codegen/Tables.sol";
import {Hero, HeroData} from "../src/codegen/Tables.sol";
import {Piece, PieceData} from "../src/codegen/Tables.sol";
import {Board} from "../src/codegen/Tables.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {GameStatus} from "../src/codegen/Types.sol";
import {Utils} from "../src/library/Utils.sol";

import {TestCommon} from "./TestCommon.t.sol";

contract SynergyTest is MudTest {
    IWorld public world;

    function setUp() public override {
        super.setUp();
        world = IWorld(worldAddress);

        TestCommon.normalStart(vm, world);
    }

    function testRaceSynergy() public {
        // TestCommon.popPlayerHero(vm, world, address(2));
        TestCommon.setHero(vm, world, Player.getItemHeroes(world, address(1), 0), 0x000002, /* Axe */ 0, 0);
        TestCommon.setHero(vm, world, bytes32(hex"ffff"), 0x000103, /* Jugguernaut */ 0, 1);
        TestCommon.setHero(vm, world, bytes32(hex"eeee"), 0x000104, /* Witch Doctor */ 0, 2);
        TestCommon.setHero(vm, world, bytes32(hex"dddd"), 0x000301, /* Disruptor */ 0, 3);
        TestCommon.pushPlayerHero(vm, world, address(1), bytes32(hex"ffff"));
        // TestCommon.pushPlayerHero(vm, world, address(1), bytes32(hex"eeee"));
        // TestCommon.pushPlayerHero(vm, world, address(1), bytes32(hex"dddd"));

        vm.warp(block.timestamp + 100);
        world.tick(0, address(1));
        PieceData memory piece = Piece.get(world, bytes32(uint256(1)));
        console.log(
            "piece 1 cur HP %d, initial HP %d effects %x",
            piece.health,
            Creature.getHealth(world, piece.creatureId),
            piece.effects
        );
        piece = Piece.get(world, bytes32(hex"ffff"));
        console.log(
            "piece 0xffff cur HP %d, initial HP %d, effects %x",
            piece.health,
            Creature.getHealth(world, piece.creatureId),
            piece.effects
        );

        // world.tick(0, address(1));
        // piece = Piece.get(world, bytes32(uint256(1)));
        // console.log("piece 1 cur health %d, effects %x", piece.health, piece.effects);
        // piece = Piece.get(world, bytes32(hex"ffff"));
        // console.log("piece 0xffff cur health %d, effects %x", piece.health, piece.effects);
    }
}

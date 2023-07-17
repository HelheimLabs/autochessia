// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { MudV2Test } from "@latticexyz/std-contracts/src/test/MudV2Test.t.sol";
import { Creature, CreatureData, CreatureConfig, GameConfig, Player, ShopConfig } from "../src/codegen/Tables.sol";
import { Game, GameData } from "../src/codegen/Tables.sol";
import { Hero, HeroData } from "../src/codegen/Tables.sol";
import { Piece, PieceData } from "../src/codegen/Tables.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { GameStatus } from "../src/codegen/Types.sol";

contract AutoBattleSystemTest is MudV2Test {
    IWorld public world;

    function setUp() public override {
        super.setUp();
        world = IWorld(worldAddress);
        vm.startPrank(address(1));
        world.joinRoom(bytes32("12345"));
        vm.stopPrank();

        vm.startPrank(address(2));
        world.joinRoom(bytes32("12345"));
        world.surrender();
        assertEq(Game.getWinner(world, 0), 1);
        world.joinRoom(bytes32("12345"));
        vm.stopPrank();

        vm.startPrank(address(1));
        world.joinRoom(bytes32("12345"));
        vm.stopPrank();

        // check game
        GameData memory game = Game.get(world, 1);
        assertEq(uint(game.status), uint(GameStatus.PREPARING));

        // check player coin and exp
        assertEq(Player.getCoin(world, address(1)), 2);
        assertEq(Player.getExp(world, address(1)), 1);

        // buy and place hero
        vm.startPrank(address(1));
        uint256 slotNum = ShopConfig.getSlotNum(world,0);
        for (uint i; i < slotNum; ++i) {
            uint64 hero = Player.getItemHeroAltar(world, address(1), i);
            (, uint32 tier) = world.decodeHero(hero);
            if (tier == 0) {
                world.buyHero(i);
                world.placeToBoard(0, 1, 1);
                break;
            }
        }
        vm.stopPrank();

        // vm.startPrank(address(1));
        // uint num;
        // slotNum = ShopConfig.getSlotNum(world);
        // while (num < 3) {
        //     world.buyRefreshHero();
        //     for (uint i; i < slotNum; ++i) {
        //         uint64 hero = Player.getItemHeroAltar(world, address(1), i);
        //         if (hero == 0) {
        //             world.buyHero(i);
        //             console.log("444 hero num in inventory %d", Player.lengthInventory(world, address(1)));
        //             ++num;
        //             if (num == 3) {
        //                 break;
        //             }
        //         }
        //     }
        // }
        // vm.stopPrank();
        // console.log("hero tier is %d", world.decodeHeroToTier(Player.getItemInventory(world, address(1), 0)));

        vm.startPrank(address(2));
        for (uint i; i < slotNum; ++i) {
            uint64 hero = Player.getItemHeroAltar(world, address(2), i);
            (, uint32 tier) = world.decodeHero(hero);
            if (tier == 0) {
                world.buyHero(i);
                world.placeToBoard(0, 2, 2);
                break;
            }
        }
        vm.stopPrank();

        // immediate call to autoBattle will revert with reason "preparing time"
        vm.expectRevert("preparing time");
        world.tick(1, address(1));

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions from the deployer account
        vm.startBroadcast(deployerPrivateKey);
    }

    function testWriteState() public {
        for (uint256 i; i < 10; ++i) {
            Piece.setHealth(world, bytes32(uint256(1)), 100);
        }
    }

    function testReadState1() public {
        for (uint256 i; i < 10; ++i) {
            uint32 health = Piece.getHealth(world, bytes32(uint256(1)));
        }
    }

    function testReadState2() public {
        for (uint256 i; i < 10; ++i) {
            uint32 tier = Hero.getTier(world, bytes32(uint256(1)));
            uint32 health = tier > 0
                ? (Creature.getHealth(world, Hero.getCreatureId(world, bytes32(uint256(1)))) * CreatureConfig.getItemHealthAmplifier(world, tier - 1)) / 100
                : Creature.getHealth(world, Hero.getCreatureId(world, bytes32(uint256(1))));
        }
    }

    function testReadState3() public {
        Piece.getHealth(world, bytes32(uint256(1)));
        // Piece.getX(world, bytes32(uint256(1)));
        // Piece.getY(world, bytes32(uint256(1)));
    }

    function testReadState4() public {
        Piece.get(world, bytes32(uint256(1)));
    }

    function testAutoBattle() public {
        // set block.number to 1000 would make it success
        vm.roll(1000);
        world.tick(1, address(1));
        PieceData memory piece = Piece.get(world, bytes32(uint256(1)));
        console.log("piece 1 cur health %d, x %d, y %d", piece.health, piece.x, piece.y);
        piece = Piece.get(world, bytes32(uint256(3)));
        console.log("piece 3 cur health %d, x %d, y %d", piece.health, piece.x, piece.y);

        world.tick(1, address(1));
        piece = Piece.get(world, bytes32(uint256(1)));
        console.log("piece 1 cur health %d, x %d, y %d", piece.health, piece.x, piece.y);
        piece = Piece.get(world, bytes32(uint256(3)));
        console.log("piece 3 cur health %d, x %d, y %d", piece.health, piece.x, piece.y);


        // world.tick(666, address(123));
    }
}
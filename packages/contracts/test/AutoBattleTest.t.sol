// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {MudTest} from "@latticexyz/store/src/MudTest.sol";
import {Creature, CreatureData, GameConfig, Player, ShopConfig} from "../src/codegen/Tables.sol";
import {GameRecord, Game, GameData} from "../src/codegen/Tables.sol";
import {Hero, HeroData} from "../src/codegen/Tables.sol";
import {Piece, PieceData} from "../src/codegen/Tables.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {GameStatus} from "../src/codegen/Types.sol";
import {Utils} from "../src/library/Utils.sol";

contract AutoBattleSystemTest is MudTest {
    IWorld public world;

    function setUp() public override {
        super.setUp();
        world = IWorld(worldAddress);

        vm.startPrank(address(2));
        world.createRoom(bytes32("12345"), 3, bytes32(0));
        vm.stopPrank();

        vm.startPrank(address(1));
        world.joinRoom(bytes32("12345"));
        vm.stopPrank();

        vm.startPrank(address(2));
        world.startGame(bytes32("12345"));
        vm.stopPrank();

        // buy and place hero
        vm.startPrank(address(1));
        uint256 slotNum = ShopConfig.getSlotNum(world, 0);
        for (uint256 i; i < slotNum; ++i) {
            uint256 hero = Player.getItemHeroAltar(world, address(1), i);
            uint256 tier = Utils.getHeroTier(hero);
            if (tier == 0) {
                world.buyHero(i);
                world.placeToBoard(0, 1, 1);
                break;
            }
        }
        vm.stopPrank();

        vm.startPrank(address(2));
        for (uint256 i; i < slotNum; ++i) {
            uint64 hero = Player.getItemHeroAltar(world, address(2), i);
            uint256 tier = Utils.getHeroTier(hero);
            if (tier == 0) {
                world.buyHero(i);
                world.placeToBoard(0, 2, 2);
                break;
            }
        }
        vm.stopPrank();

        // immediate call to autoBattle will revert with reason "preparing time"
        vm.expectRevert("preparing time");
        world.tick(0, address(1));
    }

    function testMerge() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // Start broadcasting transactions from the deployer account
        vm.startBroadcast(deployerPrivateKey);
        // set price for refreshing hero to 0
        ShopConfig.setRefreshPrice(world, 0, 0);
        // set price for hero of tier 0 to 0
        ShopConfig.updateTierPrice(world, 0, 0, 0);
        // set player tier to 3
        Player.setTier(world, address(1), 3);
        // set the first hero to tier 2 in case of affecting merge test
        Hero.setCreatureId(world, Player.getItemHeroes(world, address(1), 0), (2 << 8) + 1);
        vm.stopBroadcast();

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
        // set block.timestamp to current+100s would make it success
        vm.warp(block.timestamp + 100);
        world.tick(0, address(1));
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

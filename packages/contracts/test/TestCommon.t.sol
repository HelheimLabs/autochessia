// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {Creature, CreatureData, GameConfig, Player, ShopConfig} from "../src/codegen/Tables.sol";
import {GameRecord, Game, GameData} from "../src/codegen/Tables.sol";
import {Hero, HeroData} from "../src/codegen/Tables.sol";
import {Piece, PieceData} from "../src/codegen/Tables.sol";
import {Board} from "../src/codegen/Tables.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {GameStatus} from "../src/codegen/Types.sol";
import {Utils} from "../src/library/Utils.sol";

library TestCommon {
    function normalStart(Vm vm, IWorld world) internal {
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
    }

    function setCreatureSpeed(Vm vm, IWorld world, uint24 creatureId, uint32 speed) internal {
        startPrankDeployer(vm);
        Creature.setSpeed(world, creatureId, speed);
        vm.stopPrank();
    }

    function setHero(Vm vm, IWorld world, bytes32 heroId, uint24 creatureId, uint8 x, uint8 y) internal {
        startPrankDeployer(vm);
        Hero.set(world, heroId, creatureId, x, y);
        vm.stopPrank();
    }

    function setPlayerHero(Vm vm, IWorld world, address player, uint256 index, bytes32 heroId) internal {
        startPrankDeployer(vm);
        Player.updateHeroes(world, player, index, heroId);
        vm.stopPrank();
    }

    function pushPlayerHero(Vm vm, IWorld world, address player, bytes32 heroId) internal {
        startPrankDeployer(vm);
        Player.pushHeroes(world, player, heroId);
        vm.stopPrank();
    }

    function popPlayerHero(Vm vm, IWorld world, address player) internal {
        startPrankDeployer(vm);
        Player.popHeroes(world, player);
        vm.stopPrank();
    }

    function setPlayerCoin(Vm vm, IWorld world, address player, uint32 coin) internal {
        startPrankDeployer(vm);
        Player.setCoin(world, player, coin);
        vm.stopPrank();
    }

    function setRefreshPrice(Vm vm, IWorld world, uint8 price) internal {
        startPrankDeployer(vm);
        ShopConfig.setRefreshPrice(world, 0, price);
        vm.stopPrank();
    }

    function setPlayerTier(Vm vm, IWorld world, address player, uint8 tier) internal {
        startPrankDeployer(vm);
        Player.setTier(world, player, tier);
        vm.stopPrank();
    }

    function startPrankDeployer(Vm vm) internal {
        vm.startPrank(vm.addr(vm.envUint("PRIVATE_KEY")));
    }
}

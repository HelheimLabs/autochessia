// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {Creature, CreatureData, GameConfig, Player, ShopConfig} from "../src/codegen/index.sol";
import {GameRecord, Game, GameData} from "../src/codegen/index.sol";
import {Hero, HeroData} from "../src/codegen/index.sol";
import {Piece, PieceData} from "../src/codegen/index.sol";
import {Board} from "../src/codegen/index.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {GameStatus} from "src/codegen/common.sol";
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
        uint256 slotNum = ShopConfig.getSlotNum(0);
        for (uint256 i; i < slotNum; ++i) {
            uint256 hero = Player.getItemHeroAltar(address(1), i);
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
            uint64 hero = Player.getItemHeroAltar(address(2), i);
            uint256 tier = Utils.getHeroTier(hero);
            if (tier == 0) {
                world.buyHero(i);
                world.placeToBoard(0, 2, 2);
                break;
            }
        }
        vm.stopPrank();
    }

    function setCreatureSpeed(Vm vm, uint24 creatureId, uint32 speed) internal {
        startPrankDeployer(vm);
        Creature.setSpeed(creatureId, speed);
        vm.stopPrank();
    }

    function setHero(Vm vm, bytes32 heroId, uint24 creatureId, uint8 x, uint8 y) internal {
        startPrankDeployer(vm);
        Hero.set(heroId, creatureId, x, y);
        vm.stopPrank();
    }

    function setPlayerHero(Vm vm, address player, uint256 index, bytes32 heroId) internal {
        startPrankDeployer(vm);
        Player.updateHeroes(player, index, heroId);
        vm.stopPrank();
    }

    function pushPlayerHero(Vm vm, address player, bytes32 heroId) internal {
        startPrankDeployer(vm);
        Player.pushHeroes(player, heroId);
        vm.stopPrank();
    }

    function popPlayerHero(Vm vm, address player) internal {
        startPrankDeployer(vm);
        Player.popHeroes(player);
        vm.stopPrank();
    }

    function setPlayerCoin(Vm vm, address player, uint32 coin) internal {
        startPrankDeployer(vm);
        Player.setCoin(player, coin);
        vm.stopPrank();
    }

    function setRefreshPrice(Vm vm, uint8 price) internal {
        startPrankDeployer(vm);
        ShopConfig.setRefreshPrice(0, price);
        vm.stopPrank();
    }

    function setPlayerTier(Vm vm, address player, uint8 tier) internal {
        startPrankDeployer(vm);
        Player.setTier(player, tier);
        vm.stopPrank();
    }

    function startPrankDeployer(Vm vm) internal {
        vm.startPrank(vm.addr(vm.envUint("PRIVATE_KEY")));
    }
}

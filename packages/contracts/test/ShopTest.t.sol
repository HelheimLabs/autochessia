// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import { MudV2Test } from "@latticexyz/std-contracts/src/test/MudV2Test.t.sol";
import { Creature, CreatureData, CreatureConfig, GameConfig, Player, ShopConfig } from "../src/codegen/Tables.sol";
import { GameRecord, Game, GameData } from "../src/codegen/Tables.sol";
import { Hero, HeroData } from "../src/codegen/Tables.sol";
import { Piece, PieceData } from "../src/codegen/Tables.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { GameStatus } from "../src/codegen/Types.sol";

import { console2 } from "forge-std/console2.sol";

contract AutoBattleSystemTest is MudV2Test {
  IWorld public world;

  address _user1 = vm.addr(13);
  address _user2 = vm.addr(14);

  function setUp() public override {
    // super.setUp();
    worldAddress = abi.decode(vm.parseJson(vm.readFile("deploys/31337/latest.json"), ".worldAddress"), (address));
    world = IWorld(worldAddress);

    bytes32 roomId = bytes32("12345");

    vm.prank(_user1);
    world.createRoom(roomId, 3, bytes32(0));

    vm.prank(_user2);
    world.joinRoom(roomId);

    vm.startPrank(_user1);
    world.startGame(roomId);
    vm.stopPrank();
  }

  function testBuyHeroOne() public {
    vm.prank(_user1);
    world.buyHero(0);
  }

  function testBuyHeroTwoFail() public {
    vm.startPrank(_user1);
    world.buyHero(0);
    vm.expectRevert("empty hero slot");
    world.buyHero(0);
    vm.stopPrank();
  }

  function testBuyDifferentTwoHero() public {
    vm.startPrank(_user1);
    world.buyHero(0);
    world.buyHero(1);
    vm.stopPrank();
  }
}

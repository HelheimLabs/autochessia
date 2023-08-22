// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {MudV2Test} from "@latticexyz/std-contracts/src/test/MudV2Test.t.sol";
import {Creature, CreatureData, GameConfig, Player, ShopConfig} from "../src/codegen/Tables.sol";
import {GameRecord, Game, GameData} from "../src/codegen/Tables.sol";
import {Hero, HeroData} from "../src/codegen/Tables.sol";
import {Piece, PieceData} from "../src/codegen/Tables.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {GameStatus} from "../src/codegen/Types.sol";

import {console2} from "forge-std/console2.sol";

contract ShopSystemTest is MudV2Test {
    IWorld public world;

    address _player1 = vm.addr(13);
    address _player2 = vm.addr(14);

    uint64[] _player1InitAltar;
    uint64[] _player2InitAltar;

    function setUp() public override {
        // super.setUp();
        worldAddress = abi.decode(vm.parseJson(vm.readFile("deploys/31337/latest.json"), ".worldAddress"), (address));
        world = IWorld(worldAddress);

        bytes32 roomId = bytes32("12345");

        vm.prank(_player1);
        world.createRoom(roomId, 3, bytes32(0));

        vm.prank(_player2);
        world.joinRoom(roomId);

        vm.startPrank(_player1);
        world.startGame(roomId);
        vm.stopPrank();

        // console2.logBytes(abi.encode(Player.getHeroAltar(_player1)));
        _player1InitAltar = Player.getHeroAltar(world, _player1);
        _player2InitAltar = Player.getHeroAltar(world, _player2);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // Start broadcasting transactions from the deployer account
        vm.startBroadcast(deployerPrivateKey);
        // set player1's coin to 2
        Player.setCoin(world, _player1, 2);
        vm.stopBroadcast();
    }

    function testBuyHeroOne() public {
        // first slot not empty
        uint64 hero = Player.getItemHeroAltar(world, _player1, 0);
        assertEq(hero != 0, true);
        vm.prank(_player1);
        world.buyHero(0);
        // slot should be empty after bought
        assertEq(Player.getItemHeroAltar(world, _player1, 0), 0);
        // inventory one should be equal to bought one
        assertEq(Player.getItemInventory(world, _player1, 0), hero);
    }

    function testBuyHeroTwoFail() public {
        vm.startPrank(_player1);
        world.buyHero(0);
        // can not buy empty slot
        vm.expectRevert("empty hero altar slot");
        world.buyHero(0);
        vm.stopPrank();
    }

    function testBuyDifferentTwoHero() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // Start broadcasting transactions from the deployer account
        vm.startBroadcast(deployerPrivateKey);
        // set player1's coin to 2
        Player.setCoin(world, _player1, 2);
        vm.stopBroadcast();

        uint64 heroOne = Player.getItemHeroAltar(world, _player1, 0);
        uint64 heroTwo = Player.getItemHeroAltar(world, _player1, 1);
        vm.startPrank(_player1);

        world.buyHero(0);
        world.buyHero(1);
        vm.stopPrank();
        assertEq(Player.getItemInventory(world, _player1, 0), heroOne);
        assertEq(Player.getItemInventory(world, _player1, 1), heroTwo);
    }

    function testPlaceBackHeroToSpecificSlot(uint256 slotSeed) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // Start broadcasting transactions from the deployer account
        vm.startBroadcast(deployerPrivateKey);
        // set player1's coin to 2
        Player.setCoin(world, _player1, 2);
        vm.stopBroadcast();

        vm.startPrank(_player1);
        // buy hero
        world.buyHero(0);
        world.buyHero(1);

        uint64 heroOne = Player.getItemInventory(world, _player1, 0);
        uint64 heroTwo = Player.getItemInventory(world, _player2, 1);

        // place hero to board
        world.placeToBoard(0, 0, 1);

        // place first hero to  3th slot
        // world.placeBackInventory(0);
        world.placeBackInventoryAndSwap(0, 2);

        assertEq(Player.getItemInventory(world, _player1, 2), heroOne);
    }
}

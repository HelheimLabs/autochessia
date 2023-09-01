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

contract MatchingTest is MudTest {
    IWorld public world;

    function setUp() public override {
        super.setUp();
        world = IWorld(worldAddress);

        vm.startPrank(address(1));
        world.createRoom(bytes32("12345"), 3, bytes32(0));
        vm.stopPrank();

        vm.startPrank(address(2));
        world.joinRoom(bytes32("12345"));
        vm.stopPrank();

        vm.startPrank(address(3));
        world.joinRoom(bytes32("12345"));
        vm.stopPrank();

        vm.startPrank(address(1));
        world.startGame(bytes32("12345"));
        vm.stopPrank();
        vm.warp(block.timestamp + 100);
    }

    function testMultiplayer() public {
        vm.startPrank(address(1));
        world.surrender();
        vm.stopPrank();

        vm.startPrank(address(2));
        world.surrender();
        assertEq(GameRecord.getItem(world, 0, 2), address(3));
        world.createRoom(bytes32("12345"), 3, bytes32(0));
        vm.stopPrank();

        vm.startPrank(address(1));
        world.joinRoom(bytes32("12345"));
        vm.stopPrank();

        vm.startPrank(address(2));
        world.startGame(bytes32("12345"));
        vm.stopPrank();

        // check game
        GameData memory game = Game.get(world, 1);
        assertEq(uint256(game.status), uint256(GameStatus.PREPARING));

        // check player coin and exp
        assertEq(Player.getCoin(world, address(1)), 1);
        assertEq(Player.getExp(world, address(1)), 0);
    }

    function testSelectOpponent() public {
        _initPiece();
        _printEnemy();
        world.tick(0, address(2));
        world.tick(0, address(1));
        world.tick(0, address(3));
        vm.warp(block.timestamp + 100);
        _initPiece();
        _printEnemy();
    }

    function _initPiece() private {
        for (uint256 i = 1; i < 4; ++i) {
            world.tick(0, address(uint160(i)));
        }
    }

    function _printEnemy() private {
        address[] memory players = Game.getPlayers(world, 0);
        console.log("players [%d, %d, %d]", uint160(players[0]), uint160(players[1]), uint160(players[2]));
        for (uint256 i = 1; i < 4; ++i) {
            console.log("enemy of %d is %d", i, uint160(Board.getEnemy(world, address(uint160(i)))));
        }
    }
}

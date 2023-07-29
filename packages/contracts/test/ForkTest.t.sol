// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Creature, CreatureData, CreatureConfig, GameConfig, Player, ShopConfig } from "../src/codegen/Tables.sol";
import { GameRecord, Game, GameData } from "../src/codegen/Tables.sol";
import { Hero, HeroData } from "../src/codegen/Tables.sol";
import { Piece, PieceData } from "../src/codegen/Tables.sol";
import { Board, BoardData } from "../src/codegen/Tables.sol";

contract StartGameTest is Test {
    IWorld world;
    address user;

    function setUp() public {
        world = IWorld(vm.envAddress("WORLD_ADDR"));
        user = vm.envAddress("USER_ADDR");
    }

    function testStartGame() public {
        bytes32 roomId = bytes32(vm.envUint("ROOM_ID"));
        vm.startPrank(user);
        world.startGame(roomId);
        vm.stopPrank();
    }

    function testTick() public {
        uint32 gameId = uint32(vm.envUint("GAME_ID"));
        BoardData memory board = Board.get(world, user);
        console.log("board status %d, turn %d", uint8(board.status), board.turn);
        console.log("ally num %d, enemy num %d", board.pieces.length, board.enemyPieces.length);
        for (uint256 i; i < board.pieces.length; ++i) {
            PieceData memory piece = Piece.get(world, board.pieces[i]);
            console.log("piece id %d, (%d,%d)", uint256(board.pieces[i]), piece.x, piece.y);
            console.log("creature %d, health %d", piece.creatureId, piece.health);
        }
        for (uint256 i; i < board.pieces.length; ++i) {
            PieceData memory piece = Piece.get(world, board.enemyPieces[i]);
            console.log("enemy piece id %d, (%d,%d)", uint256(board.enemyPieces[i]), piece.x, piece.y);
            console.log("creature %d, health %d", piece.creatureId, piece.health);
        }
        world.tick(gameId, user);
    }
}
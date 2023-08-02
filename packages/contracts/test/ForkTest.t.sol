// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Creature, CreatureData, CreatureConfig, GameConfig, ShopConfig } from "../src/codegen/Tables.sol";
import { GameRecord, Game, GameData } from "../src/codegen/Tables.sol";
import { Player, PlayerData } from "../src/codegen/Tables.sol";
import { Hero, HeroData } from "../src/codegen/Tables.sol";
import { Piece, PieceData } from "../src/codegen/Tables.sol";
import { Board, BoardData } from "../src/codegen/Tables.sol";

contract ForkTest is Test {
    IWorld world;
    address user;

    function setUp() public {
        world = IWorld(vm.envAddress("WORLD_ADDR"));
        user = vm.envAddress("USER_ADDR");
    }

    /**
     * @notice usage: forge test --match-test "testStartGame*" --fork-url <rpc-url> -vvv
     */
    // function testStartGame() public {
    //     bytes32 roomId = bytes32(vm.envUint("ROOM_ID"));
    //     vm.startPrank(user);
    //     world.startGame(roomId);
    //     vm.stopPrank();
    // }

    /**
     * @notice usage: forge test --match-test "testTick*" --fork-url <rpc-url> -vvv
     */
    // function testTick() public {
    //     uint32 gameId = uint32(vm.envUint("GAME_ID"));
    //     PlayerData memory player = Player.get(world, user);
    //     for (uint256 i; i < player.heroes.length; ++i) {
    //         HeroData memory hero = Hero.get(world, player.heroes[i]);
    //         console.log("hero id %d, (%d,%d)", uint256(player.heroes[i]), hero.x, hero.y);
    //         console.log("creature %d, tier %d", hero.creatureId, hero.tier);
    //     }
    //     for (uint256 i; i < player.inventory.length; ++i) {
    //         (uint32 creatureId, uint32 tier) = world.decodeHero(player.inventory[i]);
    //         console.log("inventory index %d, creature %d, tier %d", i, creatureId, tier);
    //     }
    //     BoardData memory board = Board.get(world, user);
    //     console.log("board status %d, turn %d", uint8(board.status), board.turn);
    //     console.log("ally num %d, enemy num %d", board.pieces.length, board.enemyPieces.length);
    //     for (uint256 i; i < board.pieces.length; ++i) {
    //         PieceData memory piece = Piece.get(world, board.pieces[i]);
    //         console.log("piece id %d, (%d,%d)", uint256(board.pieces[i]), piece.x, piece.y);
    //         console.log("creature %d, tier %d, health %d", piece.creatureId, piece.tier, piece.health);
    //     }
    //     for (uint256 i; i < board.pieces.length; ++i) {
    //         PieceData memory piece = Piece.get(world, board.enemyPieces[i]);
    //         console.log("enemy piece id %d, (%d,%d)", uint256(board.enemyPieces[i]), piece.x, piece.y);
    //         console.log("creature %d, health %d", piece.creatureId, piece.tier, piece.health);
    //     }
    //     world.tick(gameId, user);
    // }
}
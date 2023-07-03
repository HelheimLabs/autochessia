// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { MudV2Test } from "@latticexyz/std-contracts/src/test/MudV2Test.t.sol";
import { Creatures, CreaturesData, GameConfig } from "../src/codegen/Tables.sol";
import { Game, GameData } from "../src/codegen/Tables.sol";
import { Piece, PieceData } from "../src/codegen/Tables.sol";
import { PieceInBattle, PieceInBattleData } from "../src/codegen/Tables.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { GameStatus } from "../src/codegen/Types.sol";

contract AutoBattleSystemTest is MudV2Test {
    IWorld public world;

    function setUp() public override {
        super.setUp();
        world = IWorld(worldAddress);
    }

    function testAutoBattle() public {
        // check pieces
        PieceData memory piece = Piece.get(world, bytes32(uint256(1)));
        assertEq(piece.creature, 1);
        assertEq(piece.tier, 0);
        assertEq(piece.x, 0);
        assertEq(piece.y, 0);
        piece = Piece.get(world, bytes32(uint256(2)));
        assertEq(piece.creature, 2);
        assertEq(piece.tier, 0);
        assertEq(piece.x, 0);
        assertEq(piece.y, 0);
        // check board
        GameData memory game = Game.get(world, 1);
        assertEq(uint(game.status), uint(GameStatus.INBATTLE));
        // check config
        assertEq(GameConfig.getLength(world), 4);
        assertEq(GameConfig.getWidth(world), 8);


        world.autoBattle(1, address(1));
        PieceInBattleData memory pieceInBattle = PieceInBattle.get(world, bytes32(uint256(1)));
        console.log("piece 1 cur health %d, x %d, y %d", pieceInBattle.curHealth, pieceInBattle.x, pieceInBattle.y);
        pieceInBattle = PieceInBattle.get(world, bytes32(uint256(4)));
        console.log("piece 4 cur health %d, x %d, y %d", pieceInBattle.curHealth, pieceInBattle.x, pieceInBattle.y);

        world.autoBattle(1, address(1));
        pieceInBattle = PieceInBattle.get(world, bytes32(uint256(1)));
        console.log("piece 1 cur health %d, x %d, y %d", pieceInBattle.curHealth, pieceInBattle.x, pieceInBattle.y);
        pieceInBattle = PieceInBattle.get(world, bytes32(uint256(4)));
        console.log("piece 4 cur health %d, x %d, y %d", pieceInBattle.curHealth, pieceInBattle.x, pieceInBattle.y);
    }
}
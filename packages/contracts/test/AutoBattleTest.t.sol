// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { MudV2Test } from "@latticexyz/std-contracts/src/test/MudV2Test.t.sol";
import { Creatures, CreaturesData, GameConfig } from "../src/codegen/Tables.sol";
import { Board, BoardData } from "../src/codegen/Tables.sol";
import { Piece, PieceData } from "../src/codegen/Tables.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { BoardStatus } from "../src/codegen/Types.sol";

contract AutoBattleSystemTest is MudV2Test {
    IWorld public world;

    function setUp() public override {
        super.setUp();
        world = IWorld(worldAddress);
    }

    function testAutoBattle() public {
        // check pieces
        PieceData memory piece = Piece.get(world, bytes32(uint256(1)));
        assertEq(piece.curHealth, 20);
        assertEq(piece.owner, 1);
        assertEq(piece.x, 7);
        assertEq(piece.y, 7);
        piece = Piece.get(world, bytes32(uint256(2)));
        assertEq(piece.curHealth, 30);
        assertEq(piece.owner, 2);
        assertEq(piece.x, 0);
        assertEq(piece.y, 0);
        // check board
        BoardData memory board = Board.get(world, bytes32(uint256(1)));
        assertEq(uint(board.status), uint(BoardStatus.INBATTLE));
        // check config
        assertEq(GameConfig.getLength(world), 8);
        assertEq(GameConfig.getWidth(world), 8);


        world.autoBattle(bytes32(uint256(1)));
        piece = Piece.get(world, bytes32(uint256(1)));
        console.log("piece 1 cur health %d, x %d, y %d", piece.curHealth, piece.x, piece.y);
        piece = Piece.get(world, bytes32(uint256(2)));
        console.log("piece 2 cur health %d, x %d, y %d", piece.curHealth, piece.x, piece.y);

        world.autoBattle(bytes32(uint256(1)));
        piece = Piece.get(world, bytes32(uint256(1)));
        console.log("piece 1 cur health %d, x %d, y %d", piece.curHealth, piece.x, piece.y);
        piece = Piece.get(world, bytes32(uint256(2)));
        console.log("piece 2 cur health %d, x %d, y %d", piece.curHealth, piece.x, piece.y);
    }
}
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { MudV2Test } from "@latticexyz/std-contracts/src/test/MudV2Test.t.sol";
import { Creatures, CreaturesData, GameConfig, Player } from "../src/codegen/Tables.sol";
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
        assertEq(piece.creature, 0);
        assertEq(piece.tier, 0);
        assertEq(piece.x, 0);
        assertEq(piece.y, 0);
        piece = Piece.get(world, bytes32(uint256(2)));
        assertEq(piece.creature, 1);
        assertEq(piece.tier, 0);
        assertEq(piece.x, 0);
        assertEq(piece.y, 0);

        vm.startPrank(address(1));
        world.joinRoom(bytes32("12345"));
        vm.stopPrank();

        vm.startPrank(address(2));
        world.joinRoom(bytes32("12345"));
        vm.stopPrank();

        // check game
        GameData memory game = Game.get(world, 0);
        assertEq(uint(game.status), uint(GameStatus.PREPARING));
        // check config
        assertEq(GameConfig.getLength(world), 4);
        assertEq(GameConfig.getWidth(world), 8);

        // check player coin and exp
        console.log("player1 coin num %d, exp %d", Player.getCoin(world, address(1)), Player.getExp(world, address(1)));
        console.log("player2 coin num %d, exp %d", Player.getCoin(world, address(2)), Player.getExp(world, address(2)));

        // immediate call to autoBattle will revert with reason "preparing time"
        vm.expectRevert("preparing time");
        world.autoBattle(0, address(1));

        // set block.number to 1000 would make it success
        vm.roll(1000);
        world.autoBattle(0, address(1));
        PieceInBattleData memory pieceInBattle = PieceInBattle.get(world, bytes32(uint256(1)));
        console.log("piece 1 cur health %d, x %d, y %d", pieceInBattle.curHealth, pieceInBattle.x, pieceInBattle.y);
        pieceInBattle = PieceInBattle.get(world, bytes32(uint256(4)));
        console.log("piece 4 cur health %d, x %d, y %d", pieceInBattle.curHealth, pieceInBattle.x, pieceInBattle.y);

        world.autoBattle(0, address(1));
        pieceInBattle = PieceInBattle.get(world, bytes32(uint256(1)));
        console.log("piece 1 cur health %d, x %d, y %d", pieceInBattle.curHealth, pieceInBattle.x, pieceInBattle.y);
        pieceInBattle = PieceInBattle.get(world, bytes32(uint256(4)));
        console.log("piece 4 cur health %d, x %d, y %d", pieceInBattle.curHealth, pieceInBattle.x, pieceInBattle.y);
    }
}
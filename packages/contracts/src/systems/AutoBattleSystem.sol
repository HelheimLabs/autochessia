// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Creatures, CreaturesData, GameConfig } from "../codegen/Tables.sol";

struct PieceOnBoard {
    bytes32 id;
    uint256 ownedBy;
    uint256 x; // position x
    uint256 y; // position y
    uint256 health;
    uint256 attack;
    uint256 range;
    uint256 defense;
    uint256 speed;
}

struct Board {
    PieceOnBoard[] pieces;
    uint256 length;
    uint256 width;
}

contract AutoBattleSystem is System {
  function autoBattle(bytes32[] calldata _ids, uint256[2][] calldata _positions, uint256 _separate) public returns (uint256) {
    // pre. create board
    // 1. check positions are valid and pieces' id are existed in the creature table
    Board memory board = createBoard(_ids, _positions, _separate);
    // 2. in a loop: a) for each piece, move towards the other piece b) for each piece, if the other piece is in its attack range,
    //  then attack it
    while (true) {
        break;
    }
    // 3. until one piece has 0 or less health, return the winner piece's owner
    return 1;
  }

  function createBoard(bytes32[] calldata _ids, uint256[2][] calldata _positions, uint256 _separate) internal returns (Board memory board) {
    uint256 pieceNum = _ids.length;
    require(pieceNum == _positions.length, "length mismatch");
    board.length = GameConfig.getLength();
    board.width = GameConfig.getWidth();
    PieceOnBoard[] memory pieces = new PieceOnBoard[](pieceNum);
    for (uint i; i < _separate; ++i) {
        CreaturesData memory data = Creatures.get(_ids[i]);
        PieceOnBoard memory piece = PieceOnBoard(_ids[i], 0, _positions[i][0], _positions[i][1], data.health, data.attack, data.range, data.defense, data.speed);
        pieces[i] = piece;
    }
    for (uint i = _separate; i < pieceNum; ++i) {
        CreaturesData memory data = Creatures.get(_ids[i]);
        PieceOnBoard memory piece = PieceOnBoard(_ids[i], 1, _positions[i][0], _positions[i][1], data.health, data.attack, data.range, data.defense, data.speed);
        pieces[i] = piece;
    }
    board.pieces = pieces;
    sanitizeBoard(board);
  }

  function sanitizeBoard(Board memory board) internal pure {
    PieceOnBoard[] memory pieces = board.pieces;
    uint256 maxX = board.length;
    uint256 maxY = board.width;
    uint256 num = pieces.length;
    for (uint i; i < num; ++i) {
        PieceOnBoard memory piece = pieces[i];
        require(piece.x < maxX, "out of boundary x");
        require(piece.y < maxY, "out of boundary y");
        require(piece.health > 0, "creature not exists");
        // sort by speed
        uint j = i;
        while ((j > 0) && (pieces[j-1].speed < piece.speed)) {
            pieces[j] = pieces[j-1];
            --j;
        }
        pieces[j] = piece;
    }
    board.pieces = pieces;
  }
}

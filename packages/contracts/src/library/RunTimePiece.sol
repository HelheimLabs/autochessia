// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Piece} from "../codegen/Tables.sol";

/**
 * @notice run-time piece
 */
struct RTPiece {
    bytes32 id; //pieceId
    bool updated;
    uint8 tier;
    uint8 owner;
    uint8 index;
    uint8 x; // position x
    uint8 y; // position y
    uint32 health;
    uint32 maxHealth;
    uint32 attack;
    uint8 range;
    uint32 defense;
    uint32 speed;
    uint8 movement;
    uint32 creatureId;
}

using RTPieceUtils for RTPiece global;

library RTPieceUtils {
    function writeBack(RTPiece memory _piece) internal {
        if (_piece.updated) {
            Piece.set(
                _piece.id,
                _piece.x,
                _piece.y,
                _piece.tier,
                _piece.health,
                _piece.attack,
                _piece.range,
                _piece.defense,
                _piece.speed,
                _piece.movement,
                _piece.maxHealth,
                _piece.creatureId
            );
        }
    }
}

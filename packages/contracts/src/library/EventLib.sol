// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct Event {
  EventType eventType;
  uint256 direct;
  uint256 indirect;
  uint256 data;
}

import "forge-std/Test.sol";
import { Player, Board, Creature, Hero, Piece, Effect, EffectData } from "../codegen/Tables.sol";
import { EventType, Attribute } from "../codegen/Types.sol";
import { RTPiece } from "./RunTimePiece.sol";
import { Coordinate as Coord } from "../library/Coordinate.sol";

library EventLib {
    function genOnMove(uint256 _moverIndex, uint256 _x, uint256 _y) internal pure returns (Event memory eve) {
        eve = Event({
            eventType: EventType.ON_MOVE,
            direct: _moverIndex,
            indirect: _moverIndex,
            data: Coord.compose(_x, _y)
        });
    }

    function genOnAttack(uint256 _attackerIndex, uint256 _targetIndex, uint256 _power) internal pure returns (Event memory eve) {
        eve = Event({
            eventType: EventType.ON_ATTACK,
            direct: _attackerIndex,
            indirect: _targetIndex,
            data: _power
        });
    }

    function genOnCastSpell(uint256 _casterIndex, uint256 _targetData, uint256 _spell) internal pure returns (Event memory eve) {
        eve = Event({
            eventType: EventType.ON_CAST_SPELL,
            direct: _casterIndex,
            indirect: _targetData,
            data: _spell
        });
    }

    function genOnDamage(uint256 _receiverIndex, uint256 _source, uint256 _damage) internal pure returns (Event memory eve) {
        eve = Event({
            eventType: EventType.ON_RECEIVE_DAMAGE,
            direct: _receiverIndex,
            indirect: _source,
            data: _damage
        });
    }

    function genOnDeath(uint256 _deadIndex, uint256 _killerIndex) internal pure returns (Event memory eve) {
        eve = Event({
            eventType: EventType.ON_RECEIVE_DAMAGE,
            direct: _killerIndex,
            indirect: _deadIndex,
            data: 0
        });
    }
}
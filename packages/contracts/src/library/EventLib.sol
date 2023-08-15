// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct Event {
    EventType eventType;
    uint256 direct;
    uint256 indirect;
    uint256 data;
}

import "forge-std/Test.sol";
import {Player, Board, Creature, Hero, Piece, Effect, EffectData} from "../codegen/Tables.sol";
import {EventType, Attribute} from "../codegen/Types.sol";
import {RTPiece} from "./RunTimePiece.sol";
import {Coordinate as Coord} from "cement/utils/Coordinate.sol";

library EventLib {
    using {_pack} for Event;

    function _pack(Event memory _eve) internal pure returns (uint256 output) {
        output += uint256(_eve.eventType) << 48;
        output += _eve.direct << 32;
        output += _eve.indirect << 16;
        output += _eve.data;
    }

    function parseEvent(uint256 _input) internal pure returns (Event memory eve) {
        eve = Event({
            eventType: EventType(_input >> 48),
            direct: uint16(_input >> 32),
            indirect: uint16(_input >> 16),
            data: uint16(_input)
        });
    }

    function genOnMove(uint256 _moverIndex, uint256 _x, uint256 _y) internal pure returns (uint256 eve) {
        eve = Event({
            eventType: EventType.ON_MOVE,
            direct: _moverIndex,
            indirect: _moverIndex,
            data: Coord.compose(_x, _y)
        })._pack();
    }

    function genOnAttack(uint256 _attackerIndex, uint256 _targetIndex, uint256 _power)
        internal
        pure
        returns (uint256 eve)
    {
        eve = Event({eventType: EventType.ON_ATTACK, direct: _attackerIndex, indirect: _targetIndex, data: _power})
            ._pack();
    }

    function genOnCastSpell(uint256 _casterIndex, uint256 _targetData, uint256 _spell)
        internal
        pure
        returns (uint256 eve)
    {
        eve = Event({eventType: EventType.ON_CAST, direct: _casterIndex, indirect: _targetData, data: _spell})._pack();
    }

    function genOnDamage(uint256 _receiverIndex, uint256 _source, uint256 _damage)
        internal
        pure
        returns (uint256 eve)
    {
        eve = Event({eventType: EventType.ON_DAMAGE, direct: _receiverIndex, indirect: _source, data: _damage})._pack();
    }

    function genOnDeath(uint256 _deadIndex, uint256 _killerIndex) internal pure returns (uint256 eve) {
        eve = Event({eventType: EventType.ON_DEATH, direct: _deadIndex, indirect: _killerIndex, data: 0})._pack();
    }
}

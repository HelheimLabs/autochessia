// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct Action {
    uint8 actionType; // 1: cast 2: attack 3: move
    uint8 executorIndex;
    uint8 targetIndex;
    uint16 value;
}

struct SubAction {
    uint8 actionType; // 1: cast 2: attack 3: move
    uint16 target; // if target > uint8.max, it's a coordinate. targetIndex if else
    uint16 value; // e.g. ability index
}

import "forge-std/Test.sol";
import {Player, Board, Creature, Hero, Piece} from "../codegen/Tables.sol";
import {RTPiece, RTPieceUtils} from "./RunTimePiece.sol";
import {EffectCache, EffectLib} from "./EffectLib.sol";
import {Event, EventLib} from "./EventLib.sol";
import {Coordinate as Coord} from "cement/utils/Coordinate.sol";
import {Queue, Q} from "./Q.sol";

library PieceActionSimulator {
    function generateCastAction(uint256 _casterIndex, uint256 _targetIndex, uint256 _abilityIndex)
        internal
        pure
        returns (uint256 action)
    {
        action += 1 << 32;
        action += _casterIndex << 24;
        action += _abilityIndex;
    }

    function generateAttackAction(uint256 _attackerIndex, uint256 _targetIndex)
        internal
        pure
        returns (uint256 action)
    {
        action += 2 << 32;
        action += _attackerIndex << 24;
        action += _targetIndex << 16;
    }

    function generateMoveAction(uint256 _moverIndex, uint256 _x, uint256 _y) internal pure returns (uint256 action) {
        action += 3 << 32;
        action += _moverIndex << 24;
        action += _x << 8;
        action += _y;
    }

    function parseAction(uint256 _action) internal pure returns (Action memory action) {
        action = Action({
            actionType: uint8(_action >> 32),
            executorIndex: uint8(_action >> 24),
            targetIndex: uint8(_action >> 16),
            value: uint16(_action)
        });
    }

    function doAction(RTPiece[] memory _pieces, uint8[][] memory _map, EffectCache memory _cache, uint256 _action)
        internal
        view
    {
        if (_action == 0) {
            return;
        }
        Action memory action = parseAction(_action);
        Queue memory q = Q.New(_pieces.length);
        uint8 actionType = action.actionType;
        if (actionType == 1) {
            _cast(_pieces, q, action.executorIndex, action.targetIndex);
        } else if (actionType == 2) {
            _attack(_pieces, q, action.executorIndex, action.targetIndex);
        } else if (actionType == 3) {
            _move(_pieces, _map, q, action.executorIndex, action.value);
        }
        while (!q.IsEmpty()) {
            uint256 eve = q.PopElement();
            _emitEvent(_pieces, EventLib.parseEvent(eve), _cache);
        }
    }

    function _cast(RTPiece[] memory _pieces, Queue memory _eventQ, uint256 _casterIndex, uint256 _targetIndex)
        private
        view
    {
        _pieces[_casterIndex].cast();

        // todo find all affected piece, if it's an ability with damage, for each affected piece, call receiveDamage
        // if else, do what is defined by this ability's description

        _pieces[_targetIndex].receiveDamage(_casterIndex, 0, _eventQ);
    }

    function _attack(RTPiece[] memory _pieces, Queue memory _eventQ, uint256 _attackerIndex, uint256 _targetIndex)
        private
        view
    {
        uint256 power = _pieces[_attackerIndex].atk(_targetIndex, _eventQ);
        _pieces[_targetIndex].receiveDamage(_attackerIndex, power, _eventQ);
    }

    function _move(
        RTPiece[] memory _pieces,
        uint8[][] memory _map,
        Queue memory _eventQ,
        uint256 _moverIndex,
        uint256 _destination
    ) private view {
        _pieces[_moverIndex].moveTo(_map, _destination, _eventQ);
    }

    function _emitEvent(RTPiece[] memory _pieces, Event memory _eve, EffectCache memory _cache) private view {
        uint256 subAction = RTPieceUtils.triggerEffectsDirect(_pieces, _eve, _cache);
        _doSubAction(_pieces, _eve, _cache, subAction);

        subAction = RTPieceUtils.triggerEffectsIndirect(_pieces, _eve, _cache);
        _doSubAction(_pieces, _eve, _cache, subAction);
    }

    // function _triggerOnCastSpell(
    //   RTPiece[] memory _pieces,
    //   Event memory _eve,
    //   EffectCache memory _cache
    // ) view private {
    //   uint256 subAction = _pieces[_eve.emitFrom].onCast(_eve, _cache);
    //   _doSubAction(_pieces, _eve, _cache, subAction);
    // }

    // function _triggerOnAttack(
    //   RTPiece[] memory _pieces,
    //   Event memory _eve,
    //   EffectCache memory _cache
    // ) view private {
    //   uint256 subAction = _pieces[_eve.emitFrom].onAttack(_eve, _cache);
    //   _doSubAction(_pieces, _eve, _cache, subAction);
    // }

    // function _triggerOnReceiveDamage(
    //   RTPiece[] memory _pieces,
    //   Event memory _eve,
    //   EffectCache memory _cache
    // ) view private {
    //   uint256 subAction = _pieces[_eve.emitFrom].onDealDamage(_eve, _cache);
    //   _doSubAction(_pieces, _eve, _cache, subAction);

    //   subAction = _pieces[_eve.applyTo].onReceiveDamage(_eve, _cache);
    //   _doSubAction(_pieces, _eve, _cache, subAction);
    // }

    // function _triggerOnMove(
    //   RTPiece[] memory _pieces,
    //   Event memory _eve,
    //   EffectCache memory _cache
    // ) view private {
    //   uint256 subAction = _pieces[_eve.applyTo].onMove(_eve, _cache);
    //   _doSubAction(_pieces, _eve, _cache, subAction);
    // }

    function _doSubAction(RTPiece[] memory _pieces, Event memory _eve, EffectCache memory _cache, uint256 _subAction)
        private
        view
    {
        if (_subAction == 0) {
            return;
        }
        // todo
    }
}

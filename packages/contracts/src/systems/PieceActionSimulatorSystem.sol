// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../library/PieceActionLib.sol";
import "../library/Constant.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "../codegen/world/IWorld.sol";
import {Player, Board, Creature, Hero, Piece} from "../codegen/Tables.sol";
import {EnvExtractor, EventType} from "../codegen/Types.sol";
import {RTPiece, RTPieceUtils} from "../library/RunTimePiece.sol";
import {EffectCache, EffectLib, Trigger, Checker} from "../library/EffectLib.sol";
import {Event, EventLib} from "../library/EventLib.sol";
import {DamageLib} from "../library/DamageLib.sol";
import {Coordinate as Coord} from "cement/utils/Coordinate.sol";
import {Queue, Q} from "../library/Q.sol";

contract PieceActionSimulatorSystem is System {
    function initSimulator(RTPiece[] memory _pieces, EffectCache memory _cache)
        public
        view
        returns (RTPiece[] memory, EffectCache memory)
    {
        uint256 num = _pieces.length;
        for (uint256 i; i < num; ++i) {
            _triggerEffects(_pieces, Event(EventType.ON_START, i, 0, 0), _cache, i);
        }
        return (_pieces, _cache);
    }

    function doAction(RTPiece[] memory _pieces, uint8[][] memory _map, EffectCache memory _cache, uint256 _action)
        public
        view
        returns (RTPiece[] memory, uint8[][] memory, EffectCache memory)
    {
        if (_action == 0) {
            return (_pieces, _map, _cache);
        }
        Action memory action = PieceActionLib.parseAction(_action);
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
        return (_pieces, _map, _cache);
    }

    function closeSimulator(RTPiece[] memory _pieces, EffectCache memory _cache)
        public
        view
        returns (RTPiece[] memory)
    {
        uint256 num = _pieces.length;
        for (uint256 i; i < num; ++i) {
            _triggerEffects(_pieces, Event(EventType.ON_END, i, 0, 0), _cache, i);
        }
        for (uint256 i; i < num; ++i) {
            _pieces[i].timeFly();
        }
        return _pieces;
    }

    function _updateAura(RTPiece[] memory _pieces, EffectCache memory _cache) private view {}

    function _cast(RTPiece[] memory _pieces, Queue memory _eventQ, uint256 _casterIndex, uint256 _targetIndex)
        private
        view
    {
        _pieces[_casterIndex].cast();

        // todo find all affected piece, if it's an ability with damage, for each affected piece, call receiveDamage
        // if else, do what is defined by this ability's description

        _pieces[_targetIndex].receiveDamage(_casterIndex, 0, _eventQ, 0);
    }

    function _attack(RTPiece[] memory _pieces, Queue memory _eventQ, uint256 _attackerIndex, uint256 _targetIndex)
        private
        view
    {
        uint256 dmg = _pieces[_attackerIndex].atk(_targetIndex, _eventQ);

        _pieces[_targetIndex].receiveDamage(_attackerIndex, dmg, _eventQ, IWorld(_world()).getRandomNumber());
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

    /**
     * @notice trigger certain pieces effects according to a specific event.
     * @dev we limit that only two pieces could be involved into the simulation of an event.
     */
    function _emitEvent(RTPiece[] memory _pieces, Event memory _eve, EffectCache memory _cache) private view {
        uint256 subAction = _triggerEffects(_pieces, _eve, _cache, _eve.direct);
        _doSubAction(_pieces, _eve, _cache, _eve.direct, subAction);

        subAction = _triggerEffects(_pieces, _eve, _cache, _eve.indirect);
        _doSubAction(_pieces, _eve, _cache, _eve.indirect, subAction);
    }

    function _triggerEffects(
        RTPiece[] memory _pieces,
        Event memory _eve,
        EffectCache memory _cache,
        uint256 _actorIndex
    ) internal view returns (uint256 subAction) {
        if (_actorIndex == type(uint16).max) {
            // todo trigger effects applied to env(e.g. ground)
            return 0;
        }
        uint24[PIECE_MAX_EFFECT_NUM] memory effects = _pieces[_actorIndex].effects;
        for (uint256 i; i < PIECE_MAX_EFFECT_NUM; ++i) {
            uint24 effect = effects[i];
            if (effect == 0) {
                break;
            }
            // we limit that only one(the last) sub-action is executed during each trigger process
            if (EffectLib.effectMatchEvenType(effect, _eve.eventType, _actorIndex == _eve.direct)) {
                subAction = _triggerEffect(_pieces, _eve, _cache, _actorIndex, effect);
            }
        }
    }

    function _doSubAction(
        RTPiece[] memory _pieces,
        Event memory _eve,
        EffectCache memory _cache,
        uint256 _actorIndex,
        uint256 _subAction
    ) private view {
        // we assume that no event could be triggered within a subAction
        SubAction memory subAction = PieceActionLib.parseSubAction(_subAction);
        if (subAction.actionType == 1) {
            // cast
            return;
        } else if (subAction.actionType == 2) {
            console.log("    sub action attack triggered");
            // attack
            _attack(
                _pieces, Q.New(0), _actorIndex, EffectLib.getTargetIndex(_pieces, _eve, _actorIndex, subAction.applyTo)
            );
        } else if (subAction.actionType == 3) {
            // move
            return;
        }
    }

    function _triggerEffect(
        RTPiece[] memory _pieces,
        Event memory _eve,
        EffectCache memory _cache,
        uint256 _actorIndex,
        uint24 _effect
    ) private view returns (uint256) {
        // console.log(
        //     "trigger effect, event %d, direct %d, indirect %d",
        //     uint8(_eve.eventType),
        //     _eve.direct,
        //     _eve.indirect
        // );
        // console.log("    piece index %d, id %x, effect %x", _actorIndex, uint256(_pieces[_actorIndex].id), _effect);
        Trigger memory trigger = EffectLib.parseTrigger(_cache, _effect);
        if (_checkerCheck(trigger.checker, _pieces, _actorIndex)) {
            if (trigger.hasSubAction) {
                return trigger.subAction;
            } else {
                EffectLib.applyTriggerEffects(trigger, _pieces, _eve, _cache, _actorIndex);
            }
        } else {
            // At present, there is no scenario where we remove an effect during a turn.
            // One scenario is aura effect. But we assume that the aura linger time is one turn.
            // if (trigger.hasSubAction) {
            //     return 0;
            // }
            // EffectLib.removeTriggerEffects(trigger, _pieces, _eve, _cache, _actorIndex);
        }
    }

    function _checkerCheck(Checker memory _checker, RTPiece[] memory _pieces, uint256 _actorIndex)
        internal
        view
        returns (bool)
    {
        EnvExtractor extractor = _checker.extractor;
        if (extractor == EnvExtractor.POSSIBILITY) {
            uint256 rand = IWorld(_world()).getRandomNumber();
            // console.log("checker check possibility %d, rand %d", _checker.data, rand % 100);
            return (rand % 100) < _checker.data;
        } else if (extractor == EnvExtractor.ALLY_AROUND_NUMBER) {
            // we count the piece itself as well, so we need to let the result be greater than selector
            return _extractorAllyAroundNumber(_pieces, _actorIndex, _checker.data) > _checker.selector;
        }
    }

    function _extractorAllyAroundNumber(RTPiece[] memory _pieces, uint256 _actorIndex, uint256 _distance)
        private
        view
        returns (uint256 res)
    {
        uint256 num = _pieces.length;
        RTPiece memory actor = _pieces[_actorIndex];
        for (uint256 i; i < num; ++i) {
            RTPiece memory piece = _pieces[i];
            if (piece.owner == actor.owner && Coord.distance(piece.x, piece.y, actor.x, actor.y) <= _distance) {
                ++res;
            }
        }
    }
}

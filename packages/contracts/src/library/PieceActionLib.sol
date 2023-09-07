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
    ApplyTo applyTo; //
    uint48 data; // e.g. ability index
}

using PieceActionLib for SubAction global;

import {ApplyTo} from "../codegen/Types.sol";

library PieceActionLib {
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

    function generateAttackSubAction(ApplyTo _applyTo) internal pure returns (uint64 subAction) {
        SubAction memory sa = SubAction(2, _applyTo, 0);
        return sa.pack();
    }

    function pack(SubAction memory _subAction) internal pure returns (uint64 output) {
        output += _subAction.actionType;
        output <<= 8;
        output += uint8(_subAction.applyTo);
        output <<= 48;
        output += _subAction.data;
    }

    function parseSubAction(uint256 _input) internal pure returns (SubAction memory subAction) {
        subAction.data = uint48(_input);
        subAction.applyTo = ApplyTo(uint8(_input >> 48));
        subAction.actionType = uint8(_input >> 56);
    }
}

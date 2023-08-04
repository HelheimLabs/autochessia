// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { Piece } from "../codegen/Tables.sol";
import { EffectLib } from "./EffectLib.sol";

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
  uint24[8] effects;
}

using RTPieceUtils for RTPiece global;

library RTPieceUtils {
  uint8 constant MAX_EFFECT_NUM = 8;

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
        _piece.creatureId,
        _packEffects(_piece.effects)
      );
    }
  }

  function updateAttribute(RTPiece memory _piece) internal {
    uint24[8] memory effects = _piece.effects;
    for (uint256 i; i < MAX_EFFECT_NUM; ++i) {
      uint24 effect = effects[i];
      if (effect == 0) {
        break;
      }
      EffectLib.applyModification(_piece, effect);
    }
  }

  function applyNewEffect(RTPiece memory _piece, uint24 _effect) internal {
    uint256 index;
    while (_piece.effects[index] > 0) {
      ++index;
    }
    if (index < MAX_EFFECT_NUM) {
      EffectLib.applyModification(_piece, _effect);
      _piece.effects[index] = _effect;
    }
  }

  function _sliceEffects(uint192 _effects) pure internal returns (uint24[8] memory effects) {
    uint24 effect = uint24(_effects);
    uint256 index;
    while (effect > 0) {
      effects[index] = effect;
      ++index;
      _effects >>= 24;
      effect = uint24(_effects);
    }
  }

  function _packEffects(uint24[8] memory _effects) pure internal returns (uint192 effects) {
    for (uint256 i = MAX_EFFECT_NUM - 1; i >= 0; --i) {
      effects <<= 24;
      effects += _effects[i];
    }
  }
}

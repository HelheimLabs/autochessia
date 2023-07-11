// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @notice run-time piece
 */
struct RTPiece {
  bytes32 id; //pieceId
  bool updated;
  uint32 tier;
  uint8 owner;
  uint8 index;
  uint32 x; // position x
  uint32 y; // position y
  uint32 health;
  uint32 maxHealth;
  uint32 attack;
  uint32 range;
  uint32 defense;
  uint32 speed;
  uint32 movement;
}
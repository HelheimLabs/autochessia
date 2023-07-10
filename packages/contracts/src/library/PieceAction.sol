// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct Action {
    uint8 x;
    uint8 y;
    // todo enum
    uint8 actionType; // 1: attack
    uint8 enemyIndex;
    uint16 damage;
}

// import "forge-std/Test.sol";
import { IWorld } from "../codegen/world/IWorld.sol";

library PieceAction {
  function generateAction(uint256 _x, uint256 _y, uint256 _enemyIndex, uint256 damage) internal pure returns (uint256 action) {
    action += _x;
    action << 8;
    action += _y;
    action << 8;
    action += 1;
    action << 8;
    action += _enemyIndex;
    action << 16;
    action += damage;
  }
  function spell() internal {
    // todo, cast a spell
  }

  function attack() internal {
    // todo, attack an enemy
  }

  function move() internal {
    // todo, move to a specific positon
  }

  function defend() internal {
    // todo, defend
  }
}

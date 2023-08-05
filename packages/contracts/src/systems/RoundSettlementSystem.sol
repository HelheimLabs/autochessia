// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";

import { IWorld } from "src/codegen/world/IWorld.sol";

import { Game } from "src/codegen/Tables.sol";

import { PQ, PriorityQueue } from "src/library/PQ.sol";

contract RoundSettlementSystem is System {
  using PQ for PriorityQueue;

  /**
   * @notice call as sub system internally
   * @notice shuffle players, settle all users' status after a round end
   */
  function settleRound(uint32 gameId) public {
    // shuffle players
    address[] memory players = Game.getPlayers(gameId);
    _shufflePlayers(gameId, players);

    // settle player    
    uint256 num = players.length;
    for (uint256 i; i < num; ++i) {
      _settlePlayer(gameId, players[i]);
    }
  }

  function _settlePlayer(uint32 gameId, address player) internal {
    // add experience
    IWorld(_world()).addExperience(player, 1);

    // add coin
    IWorld(_world()).updatePlayerCoin(gameId, player);

    // refresh heros
    IWorld(_world()).refreshHeroes(player);
  }

  function _shufflePlayers(uint32 _gameId, address[] memory _players) internal {
    uint256 r = IWorld(_world()).getRandomNumberInGame(_gameId);
    uint256 length = _players.length;
    PriorityQueue memory pq = PQ.New(length);
    for (uint256 i; i < length; ++i) {
      // There are at most 8 players. 
      // So we split r into 8 pieces and shuffle players according to those pieces value.
      pq.AddTask(uint160(_players[i]), uint32(r));
      r >>= 32;
    }
    for (uint256 i; i < length; ++i) {
      _players[i] = address(uint160(pq.PopTask()));
    }
  }
}

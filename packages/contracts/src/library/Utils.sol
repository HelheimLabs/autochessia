// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { Board, Game, Player, GameConfig, PieceData, Piece, PieceInBattle, Creatures, CreatureConfig } from "../codegen/Tables.sol";
import { getUniqueEntity } from "@latticexyz/world/src/modules/uniqueentity/getUniqueEntity.sol";

library Utils {
  function popInventoryByIndex(address _player, uint256 _index) internal returns (uint64 hero) {
    uint256 length = Player.lengthInventory(_player);
    if (length > _index) {
      uint64 lastHero = Player.getItemInventory(_player, length - 1);
      if ((length - 1) == _index) {
        hero = lastHero;
      } else {
        hero = Player.getItemInventory(_player, _index);
        Player.updateInventory(_player, _index, lastHero);
      }
      Player.popInventory(_player);
    } else {
      revert("inv, out of index");
    }
  }

  function popHeroAltarByIndex(address _player, uint256 _index) internal returns (uint64 hero) {
    uint256 length = Player.lengthHeroAltar(_player);
    if (length > _index) {
      uint64 lastHero = Player.getItemHeroAltar(_player, length - 1);
      if ((length - 1) == _index) {
        hero = lastHero;
      } else {
        hero = Player.getItemHeroAltar(_player, _index);
        Player.updateHeroAltar(_player, _index, lastHero);
      }
      Player.popHeroAltar(_player);
    } else {
      revert("altar, out of index");
    }
  }

  function deletePieceByIndex(address _player, uint256 _index) internal returns (PieceData memory piece) {
    uint256 length = Player.lengthPieces(_player);
    bytes32 pieceId;
    if (length > _index) {
      bytes32 lastPieceId = Player.getItemPieces(_player, length - 1);
      if ((length - 1) == _index) {
        pieceId = lastPieceId;
      } else {
        pieceId = Player.getItemPieces(_player, _index);
        Player.updatePieces(_player, _index, lastPieceId);
      }
      Player.popPieces(_player);
    } else {
      revert("piece, out of index");
    }
    piece = Piece.get(pieceId);
    Piece.deleteRecord(pieceId);
  }

  function createPieces(address _player, bool _atHome) internal returns (bytes32[] memory ids) {
    bytes32[] memory heroIds = Player.getPieces(_player);
    uint256 num = heroIds.length;
    ids = new bytes32[](num);
    for (uint256 i; i < num; ++i) {
      bytes32 heroId = heroIds[i];
      bytes32 pieceId = _atHome ? heroId : getUniqueEntity();
      PieceData memory hero = Piece.get(heroId);
      uint32 creatureId = hero.creature;
      uint8 tier = hero.tier;
      uint32 health = tier > 0
        ? (Creatures.getHealth(creatureId) * CreatureConfig.getItemHealthAmplifier(tier - 1)) / 100
        : Creatures.getHealth(creatureId);
      /// @notice key of piece is the same as hero of a player
      PieceInBattle.set(pieceId, heroId, health, _atHome ? hero.x : GameConfig.getLength() * 2 - 1 - hero.x, hero.y);
      ids[i] = pieceId;
    }
  }

  function updatePlayerStreakCount(address _player, uint256 _winner) internal {
    int256 streakCount = Player.getStreakCount(_player);
    if (_winner == 1) {
      streakCount = streakCount > 0 ? streakCount + 1 : int256(1);
    } else if (_winner == 2) {
      streakCount = streakCount < 0 ? streakCount - 1 : int256(-1);
    } else {
      // _winner == 3
      streakCount == 0;
    }
    Player.setStreakCount(_player, int8(streakCount));
  }

  function updatePlayerHealth(
    address _player,
    uint256 _winner,
    uint256 _damageTaken
  ) internal returns (uint256 health) {
    health = Player.getHealth(_player);
    if (_winner == 2) {
      health = health > _damageTaken ? health - _damageTaken : 0;
      Player.setHealth(_player, uint8(health));
    }
  }

  function incrementFinishedBoard(uint32 _gameId) internal returns (bool roundEnded) {
    uint256 finishedBoard = Game.getFinishedBoard(_gameId);
    ++finishedBoard;
    if (finishedBoard == 2) {
      roundEnded = true;
      finishedBoard = 0;
    }
    Game.setFinishedBoard(_gameId, uint8(finishedBoard));
  }

  function deleteAllPiecesInBattle(address _player) internal {
    // remove all pieces in battle on board of player
    bytes32[] memory ids = Board.getPieces(_player);
    uint256 num = ids.length;
    for (uint256 i; i < num; ++i) {
      PieceInBattle.deleteRecord(ids[i]);
    }

    ids = Board.getEnemyPieces(_player);
    num = ids.length;
    for (uint256 i; i < num; ++i) {
      PieceInBattle.deleteRecord(ids[i]);
    }

    Board.setPieces(_player, new bytes32[](0));
    Board.setEnemyPieces(_player, new bytes32[](0));
  }
}

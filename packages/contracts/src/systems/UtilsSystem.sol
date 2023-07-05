// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Board, Game, Player, GameConfig, PieceData, Piece, PieceInBattle, Creatures, CreatureConfig } from "../codegen/Tables.sol";
import { getUniqueEntity } from "@latticexyz/world/src/modules/uniqueentity/getUniqueEntity.sol";

contract UtilsSystem is System {
  function popInventoryByIndex(address _player, uint256 _index) public returns (uint64 hero) {
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

  function popHeroAltarByIndex(address _player, uint256 _index) public returns (uint64 hero) {
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

  function deletePieceByIndex(address _player, uint256 _index) public returns (PieceData memory piece) {
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

    _deletePieceInBattleByIndex(_player, _index);
  }

  /**
   * 
   * @notice private func without checking index
   */
  function _deletePieceInBattleByIndex(address _player, uint256 _index) private {
      bytes32 pieceInBattleId;
      address opponent = Board.getEnemy(_player);
      uint256 length = Board.lengthPieces(_player);

      // delete piece in battle on player's board
      bytes32 lastPieceInBattleId = Board.getItemPieces(_player, length - 1);
      if ((length - 1) == _index) {
          pieceInBattleId = lastPieceInBattleId;
      } else {
          pieceInBattleId = Board.getItemPieces(_player, _index);
          Board.updatePieces(_player, _index, lastPieceInBattleId);
      }
      Board.popPieces(_player);
      PieceInBattle.deleteRecord(pieceInBattleId);

      // delete piece in battle on opponent's board
      lastPieceInBattleId = Board.getItemEnemyPieces(opponent, length - 1);
      if ((length - 1) == _index) {
          pieceInBattleId = lastPieceInBattleId;
      } else {
          pieceInBattleId = Board.getItemEnemyPieces(opponent, _index);
          Board.updateEnemyPieces(opponent, _index, lastPieceInBattleId);
      }
      Board.popEnemyPieces(opponent);
      PieceInBattle.deleteRecord(pieceInBattleId);
  }

  function addPieceUncheckCoord(address _player, PieceData memory _piece) public {
    uint32 creatureId = _piece.creature;
    uint8 tier = _piece.tier;
    uint32 x = _piece.x;
    uint32 y = _piece.y;

    /// @dev create piece for play
    bytes32 pieceKey = getUniqueEntity();

    // create piece
    Piece.set(pieceKey, creatureId, tier, x, y);
    // add piece to player
    Player.pushPieces(_player, pieceKey);

    /// @notice key of piece in battle is the same as piece for a player
    uint32 health = tier > 0
      ? (Creatures.getHealth(creatureId) * CreatureConfig.getItemHealthAmplifier(tier - 1)) / 100
      : Creatures.getHealth(creatureId);
    PieceInBattle.set(pieceKey, pieceKey, health, x, y);
    // add piece in battle for player
    Board.pushPieces(_player, pieceKey);

    /// @dev create piece for enemy
    {
      bytes32 pieceInBattleKeyForEnemy = getUniqueEntity();

      PieceInBattle.set(pieceInBattleKeyForEnemy, pieceKey, health, GameConfig.getLength() * 2 - 1 - x, y);

      Board.pushEnemyPieces(Board.getEnemy(_player), pieceInBattleKeyForEnemy);
    }
  }

  function updatePlayerStreakCount(address _player, uint256 _winner) public {
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

  function updatePlayerHealth(address _player, uint256 _winner, uint256 _damageTaken) public returns (uint256 health) {
    health = Player.getHealth(_player);
    if (_winner == 2) {
      health = health > _damageTaken ? health - _damageTaken : 0;
      Player.setHealth(_player, uint8(health));
    }
  }

  function incrementFinishedBoard(uint32 _gameId) public returns (bool roundEnded) {
    uint256 finishedBoard = Game.getFinishedBoard(_gameId);
    ++finishedBoard;
    if (finishedBoard == 2) {
      roundEnded = true;
      finishedBoard = 0;
    }
    Game.setFinishedBoard(_gameId, uint8(finishedBoard));
  }
}
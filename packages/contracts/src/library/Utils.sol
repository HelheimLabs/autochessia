// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { Board, Game, GameRecord, PlayerGlobal, Player, GameConfig, Hero, Piece, Creature, CreatureConfig, WaitingRoom } from "../codegen/Tables.sol";
import { HeroData, CreatureData } from "../codegen/Tables.sol";
import { PlayerStatus } from "../codegen/Types.sol";
import { getUniqueEntity } from "@latticexyz/world/src/modules/uniqueentity/getUniqueEntity.sol";

library Utils {
  function popGamePlayerByIndex(uint32 _gameId, uint256 _index) internal returns (address player) {
    uint256 length = Game.lengthPlayers(_gameId);
    if (length > _index) {
      address lastPlayer = Game.getItemPlayers(_gameId, length - 1);
      if ((length - 1) == _index) {
        player = lastPlayer;
      } else {
        player = Game.getItemPlayers(_gameId, _index);
        Game.updatePlayers(_gameId, _index, lastPlayer);
      }
      Game.popPlayers(_gameId);
    } else {
      revert("player, out of index");
    }
  }

  function popWaitingRoomPlayerByIndex(bytes32 _roomId, uint256 _index) internal returns (address player) {
    uint256 length = WaitingRoom.lengthPlayers(_roomId);
    if (length > _index) {
      address lastPlayer = WaitingRoom.getItemPlayers(_roomId, length - 1);
      if ((length - 1) == _index) {
        player = lastPlayer;
      } else {
        player = WaitingRoom.getItemPlayers(_roomId, _index);
        WaitingRoom.updatePlayers(_roomId, _index, lastPlayer);
      }
      WaitingRoom.popPlayers(_roomId);
    } else {
      revert("player, out of index");
    }
  }

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

  function deleteHeroByIndex(address _player, uint256 _index) internal returns (HeroData memory hero) {
    uint256 length = Player.lengthHeroes(_player);
    bytes32 heroId;
    if (length > _index) {
      bytes32 lastHeroId = Player.getItemHeroes(_player, length - 1);
      if ((length - 1) == _index) {
        heroId = lastHeroId;
      } else {
        heroId = Player.getItemHeroes(_player, _index);
        Player.updateHeroes(_player, _index, lastHeroId);
      }
      Player.popHeroes(_player);
    } else {
      revert("piece, out of index");
    }
    hero = Hero.get(heroId);
    Hero.deleteRecord(heroId);
  }

  // function createPieces(address _player, bool _atHome) internal returns (bytes32[] memory ids) {
  //   bytes32[] memory heroIds = Player.getHeroes(_player);
  //   uint256 num = heroIds.length;
  //   ids = new bytes32[](num);
  //   for (uint256 i; i < num; ++i) {
  //     bytes32 heroId = heroIds[i];
  //     bytes32 pieceId = _atHome ? heroId : getUniqueEntity();
  //     HeroData memory hero = Hero.get(heroId);
  //     CreatureData memory data = Creature.get(hero.creatureId);
  //     uint8 tier = hero.tier;
  //     uint32 health = tier > 0
  //       ? (data.health * CreatureConfig.getItemHealthAmplifier(tier - 1)) / 100
  //       : data.health;
  //     Piece.set(
  //       pieceId,
  //       _atHome ? uint8(hero.x) : uint8(GameConfig.getLength() * 2 - 1 - hero.x),
  //       uint8(hero.y),
  //       tier,
  //       health,
  //       tier > 0 
  //         ? (data.attack * CreatureConfig.getItemAttackAmplifier(tier - 1)) / 100 
  //         : data.attack,
  //       uint8(data.range),
  //       tier > 0 
  //         ? (data.defense * CreatureConfig.getItemDefenseAmplifier(tier - 1)) / 100 
  //         : data.defense,
  //       data.speed,
  //       uint8(data.movement),
  //       health,
  //       hero.creatureId
  //     );
  //     ids[i] = pieceId;
  //   }
  // }

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

  function settleBoard(uint32 _gameId, address _player, uint256 _playerHealth) internal returns (bool roundEnded, bool gameFinished) {
    (int256 index, address[] memory players) = getIndexOfLivingPlayers(_gameId, _player);
    popGamePlayerByIndex(_gameId, uint256(index));

    uint256 num = players.length;
    uint256 finishedBoard = Game.getFinishedBoard(_gameId);
    if (_playerHealth == 0) {
      // release defeated player
      clearPlayer(_gameId, _player);
      --num;
    } else {
      // push back into player list. this changes the order of player as well.
      Game.pushPlayers(_gameId, _player);
      ++finishedBoard;
    }

    if (finishedBoard == num) {
      roundEnded = true;
      finishedBoard = 0;
      if (num < 2) {
        gameFinished = true;
        // just return, no need to set finished board because game would be deleted entirely
        return (roundEnded, gameFinished);
      }
    } 
    Game.setFinishedBoard(_gameId, uint8(finishedBoard));
  }

  function clearPlayer(uint32 _gameId, address _player) internal {
    GameRecord.push(_gameId, _player);
    PlayerGlobal.setStatus(_player, PlayerStatus.UNINITIATED);
    deleteAllHeroes(_player);
    Player.deleteRecord(_player);
  }

  function deleteAllHeroes(address _player) internal {
    // remove all heroes placed on board by player
    bytes32[] memory ids = Player.getHeroes(_player);
    uint256 num = ids.length;
    for (uint256 i; i < num; ++i) {
      Hero.deleteRecord(ids[i]);
    }
  }

  function deleteAllPieces(address _player) internal {
    // remove all pieces in battle on board of player
    bytes32[] memory ids = Board.getPieces(_player);
    uint256 num = ids.length;
    for (uint256 i; i < num; ++i) {
      Piece.deleteRecord(ids[i]);
    }

    ids = Board.getEnemyPieces(_player);
    num = ids.length;
    for (uint256 i; i < num; ++i) {
      Piece.deleteRecord(ids[i]);
    }

    Board.setPieces(_player, new bytes32[](0));
    Board.setEnemyPieces(_player, new bytes32[](0));
  }

  function getIndexOfLivingPlayers(uint32 _gameId, address _player) internal returns (int256 index, address[] memory players) {
    players = Game.getPlayers(_gameId);
    uint256 num = players.length;
    for (uint256 i; i < num; ++i) {
      if (_player == players[i]) {
        return (int256(i), players);
      }
    }
    return (-1, players);
  }
}

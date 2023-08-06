// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { Board, Game, GameRecord, PlayerGlobal, Player, GameConfig, Hero, Piece, Creature, CreatureConfig, WaitingRoom } from "../codegen/Tables.sol";
import { HeroData, CreatureData } from "../codegen/Tables.sol";
import { PlayerStatus, BoardStatus } from "../codegen/Types.sol";
import { getUniqueEntity } from "@latticexyz/world/src/modules/uniqueentity/getUniqueEntity.sol";

library Utils {
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
      hero = Player.getItemInventory(_player, _index);

      // set the index as 0
      Player.updateInventory(_player, _index, uint64(0));
    } else {
      revert("inv, out of index");
    }
  }

  function getFirstInventoryEmptyIdx(address _player) internal view returns (uint256) {
    uint64[] memory inv = Player.getInventory(_player);
    uint256 length = inv.length;
    for (uint256 i = 0; i < length; ) {
      if (inv[i] == uint64(0)) {
        return i;
      }
      unchecked {
        i++;
      }
    }
    revert("inventory full");
  }

  function removeHeroByIndex(address _player, uint256 _index) internal returns (HeroData memory hero) {
    uint256 length = Player.lengthHeroes(_player);
    bytes32 heroId;
    if (_index < length) {
      bytes32 removeHeroId = Player.getItemHeroes(_player, _index);

      for (uint i = _index; i < (length - 1); i++) {
        heroId = Player.getItemHeroes(_player, i + 1);
        Player.updateHeroes(_player, i, heroId);
      }

      Player.popHeroes(_player);

      hero = Hero.get(removeHeroId);
      Hero.deleteRecord(removeHeroId);
    } else {
      revert("piece, out of index");
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

  function clearPlayer(uint32 _gameId, address _player) internal {
    Board.deleteRecord(_player);
    popGamePlayer(_gameId, _player);
    GameRecord.push(_gameId, _player);
    PlayerGlobal.deleteRecord(_player);
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
  }

  function getIndexOfLivingPlayers(
    uint32 _gameId,
    address _player
  ) internal returns (uint256 index, address[] memory players) {
    players = Game.getPlayers(_gameId);
    uint256 num = players.length;
    for (uint256 i; i < num; ++i) {
      if (_player == players[i]) {
        return (i, players);
      }
    }
    revert("player not found");
  }

  function popGamePlayer(uint32 _gameId, address _player) internal {
    (uint256 index, address[] memory players) = getIndexOfLivingPlayers(_gameId, _player);
    uint256 lastIndex = players.length - 1;
    if (index < lastIndex) {
      Game.updatePlayers(_gameId, index, players[lastIndex]);
    }
    Game.popPlayers(_gameId);
  }
}

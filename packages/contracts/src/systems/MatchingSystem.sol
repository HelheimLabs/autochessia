// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { PlayerGlobal, Player, Game, WaitingRoom, GameConfig, Board } from "../codegen/Tables.sol";
import { PlayerStatus, GameStatus, BoardStatus } from "../codegen/Types.sol";
import { Utils } from "../library/Utils.sol";

contract MatchingSystem is System {
  function joinRoom(bytes32 _roomId) public {
    require(_roomId != bytes32(0), "invalid room id");
    address player = _msgSender();
    require(PlayerGlobal.getStatus(player) == PlayerStatus.UNINITIATED, "still in game");
    bytes32 prevRoomId = PlayerGlobal.getRoomId(player);
    require(PlayerGlobal.getRoomId(player) != _roomId, "already in room");
    if (prevRoomId != bytes32(0)) {
      _leaveRoom(prevRoomId, player);
    }

    if (WaitingRoom.getPlayer1(_roomId) == address(0)) {
      WaitingRoom.setPlayer1(_roomId, player);
      PlayerGlobal.setRoomId(player, _roomId);
    } else {
      address player1 = WaitingRoom.getPlayer1(_roomId);
      // start a game
      startGame(player1, player);
      // delete waiting room
      WaitingRoom.deleteRecord(_roomId);
    }
  }

  function leaveRoom(bytes32 _roomId) public {
    require(_roomId != bytes32(0), "invalid room id");
    _leaveRoom(_roomId, _msgSender());
  }

  function _leaveRoom(bytes32 _roomId, address _player) internal {
    if (WaitingRoom.getPlayer1(_roomId) == _player) {
      WaitingRoom.deleteRecord(_roomId);
      PlayerGlobal.setRoomId(_player, bytes32(0));
    }
  }

  function startGame(address _player1, address _player2) internal {
    uint32 gameIndex = GameConfig.getGameIndex();
    uint64 roundInterval = GameConfig.getRoundInterval();
    Game.set(
      gameIndex,
      _player1,
      _player2,
      GameStatus.PREPARING,
      0, // round
      uint64(block.number) + roundInterval, // start from
      0, // finished board
      0, // winner
      0 // global random number, initially set it to 0
    );

    /// @dev request global random number
    /// @dev but skip some development network
    if (block.chainid != 31337 && block.chainid != 421613 && block.chainid != 4242) {
      IWorld(_world()).requestGlobalRandomNumber(gameIndex);
    }

    PlayerGlobal.set(_player1, bytes32(0), gameIndex, PlayerStatus.INGAME);
    Player.setHealth(_player1, 100);
    PlayerGlobal.set(_player2, bytes32(0), gameIndex, PlayerStatus.INGAME);
    Player.setHealth(_player2, 100);
    // init round 0 for each player
    IWorld(_world()).settleRound(gameIndex);
    GameConfig.setGameIndex(gameIndex + 1);
  }

  function surrender() public {
    address player = _msgSender();
    require(PlayerGlobal.getStatus(player) == PlayerStatus.INGAME, "not in game");
    uint32 gameId = PlayerGlobal.getGameId(player);
    address opponent;

    // update game
    Game.setStatus(gameId, GameStatus.FINISHED);
    if (Game.getPlayer1(gameId) == player) {
      Game.setWinner(gameId, 2);
      opponent = Game.getPlayer2(gameId);
    } else {
      Game.setWinner(gameId, 1);
      opponent = Game.getPlayer1(gameId);
    }

    // reset board
    Board.setStatus(player, BoardStatus.UNINITIATED);
    Board.setStatus(opponent, BoardStatus.UNINITIATED);
    Utils.deleteAllPieces(player);
    Utils.deleteAllPieces(opponent);

    // reset player
    PlayerGlobal.setStatus(player, PlayerStatus.UNINITIATED);
    PlayerGlobal.setStatus(opponent, PlayerStatus.UNINITIATED);
    Utils.deleteAllHeroes(player);
    Utils.deleteAllHeroes(opponent);
    Player.deleteRecord(player);
    Player.deleteRecord(opponent);
  }
}

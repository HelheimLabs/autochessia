// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { PlayerGlobal, PlayerGlobalData, Player, Game, WaitingRoom, WaitingRoomData, WaitingRoomPassword, GameConfig, Board } from "../codegen/Tables.sol";
import { PlayerStatus, GameStatus, BoardStatus } from "../codegen/Types.sol";
import { Utils } from "../library/Utils.sol";

contract MatchingSystem is System {
  function createRoom(bytes32 _roomId, uint8 _seatNum, bytes32 _passwordHash) public {
    require(_roomId != bytes32(0), "invalid room id");
    require(WaitingRoom.getSeatNum(_roomId) == 0, "room exists");
    // todo allow PvE
    require(_seatNum > 1, "invalid seat num");

    address creator = _msgSender();
    PlayerGlobalData memory creatorG = PlayerGlobal.get(creator);
    require(creatorG.status == PlayerStatus.UNINITIATED, "still in game");
    require(creatorG.roomId == bytes32(0), "still in room");

    _createRoom(creator, _roomId, _seatNum, _passwordHash);
  }

  /**
   * 
   * @notice join in a public room
   */
  function joinRoom(bytes32 _roomId) public {
    require(_roomId != bytes32(0), "invalid room id");
    WaitingRoomData memory room = WaitingRoom.get(_roomId);
    require(room.seatNum > 0, "room not exist");
    require(room.players.length < room.seatNum, "room is full");

    address player = _msgSender();
    PlayerGlobalData memory playerG = PlayerGlobal.get(player);
    require(playerG.status == PlayerStatus.UNINITIATED, "still in game");
    require(playerG.roomId == bytes32(0), "still in room");

    WaitingRoom.pushPlayers(_roomId, player);
    PlayerGlobal.setRoomId(player, _roomId);
  }

  function leaveRoom(bytes32 _roomId, uint256 _index) public {
    address player = _msgSender();
    _leaveRoom(player, _roomId, _index);
  }

  function startGame(bytes32 _roomId) public {
    require(_roomId != bytes32(0), "invalid room id");
    WaitingRoomData memory room = WaitingRoom.get(_roomId);
    address[] memory players = room.players;
    uint256 num = players.length;
    // todo allow single player versus Environment
    require(num > 1, "at least 2 players");
    address player = _msgSender();
    require(players[0] == player, "not room creator");
    
    // todo modify
    _startGame(player, players[1]);
    WaitingRoom.deleteRecord(_roomId);
    if (room.withPassword) {
      WaitingRoomPassword.deleteRecord(_roomId);
    }
  }

  function _createRoom(address _creator, bytes32 _roomId, uint8 _seatNum, bytes32 _passwordHash) private {
    address[] memory players = new address[](1);
    players[0] = _creator;
    bool withPassword = _passwordHash == bytes32(0);
    WaitingRoom.set(_roomId, _seatNum, withPassword, players);
    if (withPassword) {
      WaitingRoomPassword.set(_roomId, _passwordHash);
    }
    PlayerGlobal.setRoomId(_creator, _roomId);
  }

  function _leaveRoom(address _player, bytes32 _roomId, uint256 _index) private {
    require(Utils.popPlayerByIndex(_roomId, _index) == _player, "mismatch player");
    PlayerGlobal.setRoomId(_player, bytes32(0));
    // creator of this room leaves
    if (_index == 0) {
      address[] memory players = WaitingRoom.getPlayers(_roomId);
      WaitingRoom.deleteRecord(_roomId);
      WaitingRoomPassword.deleteRecord(_roomId);
      uint256 num = players.length;
      if (num > 0) {
        for (uint256 i; i < num; ++i) {
          PlayerGlobal.setRoomId(players[i], bytes32(0));
        }
      }
    }
  }

  // todo modify
  function _startGame(address _player1, address _player2) private {
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

  // todo modify
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

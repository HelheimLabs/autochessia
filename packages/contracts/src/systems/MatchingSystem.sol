// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "../codegen/world/IWorld.sol";
import {
    PlayerGlobal,
    Player,
    GameRecord,
    Game,
    WaitingRoom,
    WaitingRoomPassword,
    GameConfig,
    Board
} from "../codegen/Tables.sol";
import {PlayerGlobalData, WaitingRoomData} from "../codegen/Tables.sol";
import {PlayerStatus, GameStatus, BoardStatus} from "../codegen/Types.sol";
import {Utils} from "../library/Utils.sol";

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
        require(!room.withPassword, "PrivateRoom!");
        require(room.players.length < room.seatNum, "room is full");

        address player = _msgSender();
        PlayerGlobalData memory playerG = PlayerGlobal.get(player);
        require(playerG.status == PlayerStatus.UNINITIATED, "still in game");
        require(playerG.roomId == bytes32(0), "still in room");

        _enterRoom(player, _roomId);
    }

    /**
     *
     * @notice join in a private room
     */
    function joinPrivateRoom(
        bytes32 _roomId,
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC
    ) public {
        require(_roomId != bytes32(0), "invalid room id");
        WaitingRoomData memory room = WaitingRoom.get(_roomId);
        require(room.seatNum > 0, "room not exist");
        require(room.withPassword, "PublicRoom!");
        require(room.players.length < room.seatNum, "room is full");

        address player = _msgSender();
        PlayerGlobalData memory playerG = PlayerGlobal.get(player);
        require(playerG.status == PlayerStatus.UNINITIATED, "still in game");
        require(playerG.roomId == bytes32(0), "still in room");

        bytes32 passwordHash = WaitingRoomPassword.get(_roomId);
        uint256[3] memory pubSignals =
            [uint256(passwordHash) >> 128, uint128(uint256(passwordHash)), uint256(uint160(player))];
        require(IWorld(_world()).verifyPasswordProof(_pA, _pB, _pC, pubSignals), "invalid password proof");

        _enterRoom(player, _roomId);
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

        _startGame(players);
        WaitingRoom.deleteRecord(_roomId);
        if (room.withPassword) {
            WaitingRoomPassword.deleteRecord(_roomId);
        }
    }

    function _createRoom(address _creator, bytes32 _roomId, uint8 _seatNum, bytes32 _passwordHash) private {
        address[] memory players = new address[](1);
        players[0] = _creator;
        bool withPassword = _passwordHash != bytes32(0);
        WaitingRoom.set(_roomId, _seatNum, withPassword, uint64(block.number), uint64(block.number), players);
        if (withPassword) {
            WaitingRoomPassword.set(_roomId, _passwordHash);
        }
        PlayerGlobal.setRoomId(_creator, _roomId);
    }

    function _enterRoom(address _player, bytes32 _roomId) private {
        WaitingRoom.pushPlayers(_roomId, _player);
        WaitingRoom.setUpdatedAtBlock(_roomId, uint64(block.number));
        PlayerGlobal.setRoomId(_player, _roomId);
    }

    function _leaveRoom(address _player, bytes32 _roomId, uint256 _index) private {
        require(Utils.popWaitingRoomPlayerByIndex(_roomId, _index) == _player, "mismatch player");
        PlayerGlobal.setRoomId(_player, bytes32(0));
        WaitingRoom.setUpdatedAtBlock(_roomId, uint64(block.number));
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

    function _startGame(address[] memory _players) private {
        uint32 gameIndex = GameConfig.getGameIndex(0);
        GameConfig.setGameIndex(0, gameIndex + 1);
        uint32 roundInterval = GameConfig.getRoundInterval(0);
        Game.set(
            gameIndex,
            GameStatus.PREPARING,
            0, // round
            uint32(block.timestamp) + roundInterval, // round start timestamp
            0, // finished board
            0, // global random number, initially set it to 0
            _players
        );

        /// @dev request global random number
        /// @dev but skip some development network
        // if (block.chainid != 31337 && block.chainid != 421613 && block.chainid != 4242) {
        //   IWorld(_world()).requestGlobalRandomNumber(gameIndex);
        // }

        /// @dev initalize inventory
        uint64[] memory inventory = new uint64[](GameConfig.getInventorySlotNum(0));

        uint256 num = _players.length;
        for (uint256 i; i < num; ++i) {
            address player = _players[i];
            PlayerGlobal.set(player, bytes32(0), gameIndex, PlayerStatus.INGAME);
            Player.setHealth(player, 30);
            Player.setInventory(player, inventory);
        }

        // init round 0 for each player
        IWorld(_world()).settleRound(gameIndex);
    }
}

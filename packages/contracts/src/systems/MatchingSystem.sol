// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { Player, Game, WaitingRoom, GameConfig } from "../codegen/Tables.sol";
import { PlayerStatus, GameStatus } from "../codegen/Types.sol";

contract MatchingSystem is System {
    function joinRoom(bytes32 _roomId) public {
        require(_roomId != bytes32(0), "invalid room id");
        address player = _msgSender();
        require(Player.getStatus(player) == PlayerStatus.UNINITIATED, "still in game");

        if (WaitingRoom.getPlayer1(_roomId) == address(0)) {
            WaitingRoom.setPlayer1(_roomId, player);
            // todo leave previous room if exists
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
        if (WaitingRoom.getPlayer1(_roomId) == _msgSender()) {
            WaitingRoom.deleteRecord(_roomId);
        }
    }

    function startGame(address _player1, address _player2) internal {
        uint32 gameIndex = GameConfig.getGameIndex();
        Game.set(
            gameIndex,
            _player1,
            _player2,
            GameStatus.PREPARING,
            0, // round
            0, // finished board
            0  // winner
        );
        Player.set(_player1, gameIndex, PlayerStatus.INGAME, 100, 0, 0, 0, 0, new bytes32[](0), new uint64[](0), new uint64[](0));
        Player.set(_player2, gameIndex, PlayerStatus.INGAME, 100, 0, 0, 0, 0, new bytes32[](0), new uint64[](0), new uint64[](0));
        // init round 0 for each player
        IWorld(_world()).settleRound(gameIndex);
        GameConfig.setGameIndex(gameIndex+1);
    }
}
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { System } from "@latticexyz/world/src/System.sol";
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
            uint32 gameIndex = GameConfig.getGameIndex();
            address player1 = WaitingRoom.getPlayer1(_roomId);
            Game.set(
                gameIndex,
                WaitingRoom.getPlayer1(_roomId),
                player,
                GameStatus.PREPARING,
                0, // round
                0, // finished board
                0  // winner
            );
            Player.set(player, gameIndex, PlayerStatus.INGAME, 100, 0, 0, 0, 0, new bytes32[](0), new uint64[](0), new uint64[](0));
            Player.set(player1, gameIndex, PlayerStatus.INGAME, 100, 0, 0, 0, 0, new bytes32[](0), new uint64[](0), new uint64[](0));
            GameConfig.setGameIndex(gameIndex+1);
            WaitingRoom.deleteRecord(_roomId);
        }
    }

    function leaveRoom(bytes32 _roomId) public {
        require(_roomId != bytes32(0), "invalid room id");
        if (WaitingRoom.getPlayer1(_roomId) == _msgSender()) {
            WaitingRoom.deleteRecord(_roomId);
        }
    }
}
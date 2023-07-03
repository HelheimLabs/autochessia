// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Player, Game } from "../codegen/Tables.sol";
import { PlayerStatus, GameStatus } from "../codegen/Types.sol";

contract JoinGameSystem is System {
    function joinGame(uint32 _gameId) public {
        address player = _msgSender();
        require(Player.getStatus(player) == PlayerStatus.UNINITIATED, "still in game");
        require(Game.getStatus(_gameId) == GameStatus.UNINITIATED, "game started");
        if (Game.getPlayer1(_gameId) == address(0)) {
            Game.setPlayer1(_gameId, player);
            uint32 prevGameId = Player.getGameId(player);
            Game.setPlayer1(prevGameId, address(0));
            // Game.deleteRecord(prevGameId);
        } else {
            Game.setPlayer2(_gameId, player);
            Game.setStatus(_gameId, GameStatus.PREPARING);
            Player.set(player, _gameId, PlayerStatus.INGAME, 100, 0, 0, 0, new bytes32[](0), new uint64[](0), new uint64[](0));
            address player1 = Game.getPlayer1(_gameId);
            Player.set(player1, _gameId, PlayerStatus.INGAME, 100, 0, 0, 0, new bytes32[](0), new uint64[](0), new uint64[](0));
        }
    }
}
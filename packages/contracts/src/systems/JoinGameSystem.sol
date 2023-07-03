// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Player, Game } from "../codegen/Tables.sol";
import { PlayerStatus, GameStatus } from "../codegen/Types.sol";

contract JoinGameSystem is System {
    function joinGame(bytes32 _gameId) public {
        address addr = _msgSender();
        bytes32 playerId = bytes32(uint256(uint160(addr)));
        require(Player.getStatus(playerId) == PlayerStatus.UNINITIATED, "still in game");
        require(Game.getStatus(_gameId) == GameStatus.UNINITIATED, "game started");
        if (Game.getPlayer1(_gameId) == address(0)) {
            Game.setPlayer1(_gameId, addr);
            bytes32 prevGameId = Player.getGameId(playerId);
            Game.setPlayer1(prevGameId, address(0));
            // Game.deleteRecord(prevGameId);
        } else {
            Game.setPlayer2(_gameId, addr);
            Game.setStatus(_gameId, GameStatus.PREPARING);
            Player.set(playerId, _gameId, PlayerStatus.INGAME, 100, 0, 0, 0, new bytes32[](0), new uint64[](0), new uint64[](0));
            address player1 = Game.getPlayer1(_gameId);
            Player.set(bytes32(uint256(uint160(player1))), _gameId, PlayerStatus.INGAME, 100, 0, 0, 0, new bytes32[](0), new uint64[](0), new uint64[](0));
        }
    }
}
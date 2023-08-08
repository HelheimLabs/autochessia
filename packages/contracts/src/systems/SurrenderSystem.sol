// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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
import {PlayerStatus, GameStatus, BoardStatus} from "../codegen/Types.sol";
import {Utils} from "../library/Utils.sol";

contract SurrenderSystem is System {
    function surrender() public {
        address player = _msgSender();
        require(PlayerGlobal.getStatus(player) == PlayerStatus.INGAME, "not in game");
        uint32 gameId = PlayerGlobal.getGameId(player);
        require(Game.getStatus(gameId) == GameStatus.PREPARING, "only during preparing");

        // clear board
        Utils.deleteAllPieces(player);

        // clear player
        Utils.clearPlayer(gameId, player);
    }
}

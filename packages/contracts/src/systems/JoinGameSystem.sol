// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Player, Board } from "../codegen/Tables.sol";

contract JoinGameSystem is System {
    function joinGame(bytes32 _boardId) public {
        address addr = _msgSender();
        bytes32 playerId = bytes32(uint256(uint160(addr)));
        bytes32 curBoadrId = Player.get(playerId);
        if ((curBoadrId == bytes32(0)) || (Board.getPlayer2(curBoadrId) == address(0))) {
            if (Board.getPlayer1(_boardId) == address(0)) {
                Board.setPlayer1(_boardId, addr);
            } else if (Board.getPlayer2(_boardId) == address(0)) {
                Board.setPlayer2(_boardId, addr);
            } else {
                revert("full board");
            }
            Player.set(playerId, _boardId);
        }
        revert("still in game");
    }
}
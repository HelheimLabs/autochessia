// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Piece, Player, Game, PieceData } from "../codegen/Tables.sol";
import { GameStatus } from "../codegen/Types.sol";
import { IWorld } from "src/codegen/world/IWorld.sol";

contract MergeSystem is System {
    uint8 public constant mergeNum = 3;

    function merge(address _player, uint64 _hero) public returns (bool merged, uint64 mergedHero) {
        IWorld world = IWorld(_world());
        // tier max = 2
        if (world.decodeHeroToTier(_hero) > 1) {
            return (false, _hero);
        }
        uint256[2] memory indexes;
        bool[2] memory onBoard;
        uint256 num;
        // search priority: piece on board hight than hero in inventory
        uint256 length = Player.lengthPieces(_player);
        for (uint i; i < length; ++i) {
            bytes32 pieceId = Player.getItemPieces(_player, i);
            if (_hero == world.encodeHero(Piece.getCreature(pieceId), Piece.getTier(pieceId))) {
                indexes[num] = i;
                onBoard[num] = true;
                ++num;
            }
            if (num == 2) {
                mergeHero(_player, indexes, onBoard);
                return (true, world.levelUpHero(_hero));
            }
        }

        length = Player.lengthInventory(_player);
        for (uint i; i < length; ++i) {
            if (_hero == Player.getItemInventory(_player, i)) {
                indexes[num] = i;
                ++num;
            }
            if (num == 2) {
                mergeHero(_player, indexes, onBoard);
                return (true, world.levelUpHero(_hero));
            }
        }
    }

    /**
     * 
     * @param _player player address
     * @param _indexes an array of indexes of player's piece on board or hero in inventory that he wants to merge
     * @param _onBoard an array of bool which indicates whether the corresponding index is based on Board.pieces
     */
    function mergeHero(address _player, uint256[2] memory _indexes, bool[2] memory _onBoard) private {
        // delete pieces on board and hero in inventory
        // start from the last index to the first index. 
        // Because the indexes are put into array from lower to higher, then
        // pop a lower index would influent later popping a higher index.
        if (_onBoard[1]) {
            IWorld(_world()).deletePieceByIndex(_player, _indexes[1]);
        } else {
            IWorld(_world()).popInventoryByIndex(_player, _indexes[1]);
        }

        if (_onBoard[0]) {
            IWorld(_world()).deletePieceByIndex(_player, _indexes[0]);
        } else {
            IWorld(_world()).popInventoryByIndex(_player, _indexes[0]);
        }
    }
}
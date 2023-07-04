// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Piece, Player, Game, PieceData } from "../codegen/Tables.sol";
import { GameStatus } from "../codegen/Types.sol";
import { IWorld } from "src/codegen/world/IWorld.sol";

contract MergeSystem is System {
    uint8 public constant mergeNum = 3;

    function tryMerge(address _player, uint64 hero) public returns (bool merged) {
        uint256[2] memory indexes;
        bool[2] memory onBoard;
        uint256 num;
        // search priority: piece on board hight than hero in inventory
        uint256 length = Player.lengthPieces(_player);
        for (uint i; i < length; ++i) {
            bytes32 pieceId = Player.getItemPieces(_player, i);
            if (hero == IWorld(_world()).encodeHero(Piece.getCreature(pieceId), Piece.getTier(pieceId))) {
                indexes[num] = i;
                onBoard[num] = true;
                ++num;
            }
            if (num == 2) {
                mergeHero(_player, indexes, onBoard);
                return true;
            }
        }

        length = Player.lengthInventory(_player);
        for (uint i; i < length; ++i) {
            if (hero == Player.getItemInventory(_player, i)) {
                indexes[num] = i;
                ++num;
            }
            if (num == 2) {
                mergeHero(_player, indexes, onBoard);
                return true;
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
        PieceData memory piece;
        uint64 hero;

        for (uint i; i < 2; ++i) {
            if (_onBoard[i]) {
                piece = IWorld(_world()).deletePieceByIndex(_player, _indexes[i]);
            } else {
                hero = IWorld(_world()).popInventoryByIndex(_player, _indexes[i]);
            }
        }

        if(_onBoard[0]) {
            require(piece.tier < 2, "tier max 3");
            piece.tier += 1;
            IWorld(_world()).addPieceUncheckCoord(_player, piece);
        } else {
            (uint32 creature, uint32 tier) = IWorld(_world()).decodeHero(hero);
            require(tier < 2, "tier max 3");
            Player.pushInventory(_player, IWorld(_world()).encodeHero(creature, (tier + 1)));
        }
    }
}
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Player, Game, PieceData } from "../codegen/Tables.sol";
import { GameStatus } from "../codegen/Types.sol";
import { IWorld } from "src/codegen/world/IWorld.sol";

contract MergeSystem is System {
    uint8 public constant mergeNum = 3;

    /**
     * 
     * @param _pieceIndexes an array of indexes of player's pieces that he want to merge
     * @param _inventoryIndexes an array of indexes of player's hero in inventory that he want to merge
     */
    function mergeHero(uint256[] memory _pieceIndexes, uint256[] memory _inventoryIndexes) public {
        uint256 numOnBoard = _pieceIndexes.length;
        uint256 numInInventory = _inventoryIndexes.length;
        require(numOnBoard + numInInventory == mergeNum, "incorrect merge num");
        address player = _msgSender();

        require(Game.getStatus(Player.getGameId(player)) == GameStatus.PREPARING, "game not PREPARING");

        uint256 heroCheck = type(uint256).max;
        PieceData memory piece;

        for (uint i; i < numOnBoard; ++i) {
            piece = IWorld(_world()).deletePieceByIndex(player, _pieceIndexes[i]);
            uint256 hero = IWorld(_world()).encodeHero(piece.creature, uint32(piece.tier));
            if (heroCheck < type(uint256).max) {
                require(hero == heroCheck, "different hero");
            } else {
                heroCheck = hero;
            }
        }
        
        for (uint i; i < numInInventory; ++i) {
            uint256 hero = IWorld(_world()).popInventoryByIndex(player, _inventoryIndexes[i]);
            if (heroCheck < type(uint256).max) {
                require(hero == heroCheck, "different hero");
            } else {
                heroCheck = hero;
            }
        }

        (uint32 creature, uint32 tier) = IWorld(_world()).decodeHero(uint64(heroCheck));
        require(tier < 2, "tier max 3");
 
        if(numOnBoard > 0) {
            piece.tier += 1;
            IWorld(_world()).addPieceUncheckCoord(player, piece);
        } else {
            Player.pushInventory(player, IWorld(_world()).encodeHero(creature, (tier + 1)));
        }
    }
}
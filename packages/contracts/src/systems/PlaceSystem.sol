// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Board, Player, Game, GameConfig, Piece, PieceInBattle, Creatures } from "../codegen/Tables.sol";
import { IWorld } from "src/codegen/world/IWorld.sol";

import { getUniqueEntity } from "@latticexyz/world/src/modules/uniqueentity/getUniqueEntity.sol";

contract PlaceSystem is System {
  /**
   * @dev place hero to borad, make it a piece
   * @param index index of hero in inventory
   * @param x coordinate x to place
   * @param y coordinate y to place
   */
  function placeToBoard(uint256 index, uint32 x, uint32 y) public returns (uint32 creatureId, uint32 tier) {
    address player = _msgSender();

    // check x, y validity
    require(x < GameConfig.getWidth(), "x too large");
    require(y < GameConfig.getLength(), "y too large");

    // TODO: whether this place is occupied

    uint64 hero = Player.getItemInventory(player, index);
    (creatureId, tier) = IWorld(_world()).decodeHero(hero);

    // remove from inventory
    // 1. swap placed one with last one
    Player.updateInventory(player, index, Player.getItemInventory(player, Player.lengthInventory(player)));
    // 2. pop inventory
    Player.popInventory(player);

    bytes32 pieceKey = getUniqueEntity();
    bytes32 pieceInBattleKey = getUniqueEntity();

    // create piece
    Piece.set(pieceKey, creatureId, uint8(tier), x, y);
    // add piece to player
    Player.pushPieces(player, pieceKey);

    // create pice in battle
    PieceInBattle.set(pieceInBattleKey, pieceKey, Creatures.getHealth(creatureId), x, y);
    // add piece in battle for player
    Board.pushPieces(player, pieceInBattleKey);

    {
      bytes32 pieceInBattleKeyForEnemy = getUniqueEntity();

      // create piece for enemy
      PieceInBattle.set(
        pieceInBattleKeyForEnemy,
        pieceKey,
        Creatures.getHealth(creatureId),
        GameConfig.getWidth() * 2 - 1 - x,
        y
      );

      // add piece in battle to enemy

      uint32 gameId = Player.getGameId(player);

      // get enemy addr
      address enemyAddr;
      if (player == Game.getPlayer1(gameId)) {
        enemyAddr = Game.getPlayer2(gameId);
      } else {
        enemyAddr = Game.getPlayer1(gameId);
      }

      Board.pushPieces(enemyAddr, pieceInBattleKeyForEnemy);
    }
  }

  /**
   * @param index index of piece in pieces
   * @param x coordinate x to place
   * @param y coordinate y to place
   */
  function changePieceCoordinate(uint256 index, uint32 x, uint32 y) public {}

  /**
   * @dev
   * @param index index of piece in piece
   */
  function placeBackInventory(uint256 index) public {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Board, Player, Game, GameConfig, PieceData, Piece, PieceInBattle, Creatures, CreatureConfig } from "../codegen/Tables.sol";
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

    // check whether x,y is valid
    checkCorValidity(player, x, y);

    uint64 hero = Player.getItemInventory(player, index);
    (creatureId, tier) = IWorld(_world()).decodeHero(hero);

    // remove from inventory
    // 1. swap placed one with last one
    Player.updateInventory(player, index, Player.getItemInventory(player, Player.lengthInventory(player)));
    // 2. pop inventory
    Player.popInventory(player);

    /// @dev create piece for play
    bytes32 pieceKey = getUniqueEntity();

    // create piece
    Piece.set(pieceKey, creatureId, uint8(tier), x, y);
    // add piece to player
    Player.pushPieces(player, pieceKey);

    /// @notice key of piece in battle is the same as piece for a player
    uint32 health = tier > 0 ? Creatures.getHealth(creatureId) * CreatureConfig.getItemHealthAmplifier(tier-1) /100 : Creatures.getHealth(creatureId);
    PieceInBattle.set(pieceKey, pieceKey, health, x, y);
    // add piece in battle for player
    Board.pushPieces(player, pieceKey);

    /// @dev create piece for enemy
    {
      bytes32 pieceInBattleKeyForEnemy = getUniqueEntity();

      PieceInBattle.set(
        pieceInBattleKeyForEnemy,
        pieceKey,
        health,
        GameConfig.getLength() * 2 - 1 - x,
        y
      );

      Board.pushEnemyPieces(getEnemy(player), pieceInBattleKeyForEnemy);
    }
  }

  /**
   * @param index index of piece in pieces
   * @param x coordinate x to place
   * @param y coordinate y to place
   */
  function changePieceCoordinate(uint256 index, uint32 x, uint32 y) public {
    address player = _msgSender();
    address enemy = getEnemy(player);

    checkCorValidity(player, x, y);

    bytes32 pieceKeyForPlayer = Player.getItemPieces(player, index);
    bytes32 pieceKeyForEnemy = Board.getItemEnemyPieces(enemy, index);

    // update piece in board
    Piece.setX(pieceKeyForPlayer, x);
    Piece.setY(pieceKeyForPlayer, x);

    // update piece in piece in battle
    PieceInBattle.setX(pieceKeyForPlayer, x);
    PieceInBattle.setY(pieceKeyForPlayer, y);

    // update piece in piece in battle of enemy
    PieceInBattle.setX(pieceKeyForEnemy, GameConfig.getWidth() * 2 - 1 - x);
    PieceInBattle.setY(pieceKeyForEnemy, y);
  }

  /**
   * @dev
   * @param index index of piece in piece
   */
  function placeBackInventory(uint256 index) public {
    address player = _msgSender();
    address enemy = getEnemy(player);

    // remove from player pieces
    Player.updatePieces(player, index, Player.getItemPieces(player, Player.lengthPieces(player) - 1));
    Player.popPieces(player);

    // remove from pieces in battle
    Board.updatePieces(player, index, Board.getItemPieces(player, Board.lengthPieces(player) - 1));
    Board.popPieces(player);

    // remove from pieces in battle of enemy
    Board.updateEnemyPieces(enemy, index, Board.getItemEnemyPieces(enemy, Board.lengthEnemyPieces(enemy) - 1));
    Board.popEnemyPieces(enemy);

    /// @dev add to inventory

    bytes32 pieceKey = Player.getItemPieces(player, index);

    // check whether inventory is full
    require(Player.lengthInventory(player) < GameConfig.getInventorySlotNum(), "inventory full");

    PieceData memory pd = Piece.get(pieceKey);

    Player.pushInventory(player, IWorld(_world()).encodeHero(pd.creature, pd.tier));


    // TODO: delete piece
  }

  function checkCorValidity(address player, uint32 x, uint32 y) public view {
    // check x, y validity
    require(x < GameConfig.getWidth(), "x too large");
    require(y < GameConfig.getLength(), "y too large");

    // check whether (x,y) is empty
    uint64 cor = IWorld(_world()).encodeCor(x, y);
    // loop piece to check whether is occupied
    for (uint256 i = 0; i < Player.lengthPieces(player); i++) {
      bytes32 key = Player.getItemPieces(player, i);
      require(cor != IWorld(_world()).encodeCor(Piece.getX(key), Piece.getY(key)), "this location is not empty");
    }
  }

  function getEnemy(address player) public view returns (address enemy) {
    // add piece in battle to enemy
    uint32 gameId = Player.getGameId(player);

    if (player == Game.getPlayer1(gameId)) {
      enemy = Game.getPlayer2(gameId);
    } else {
      enemy = Game.getPlayer1(gameId);
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Board, Player, Game, GameConfig, PieceData, Piece, PieceInBattle } from "../codegen/Tables.sol";
import { GameStatus } from "../codegen/Types.sol";
import { IWorld } from "src/codegen/world/IWorld.sol";
import { getUniqueEntity } from "@latticexyz/world/src/modules/uniqueentity/getUniqueEntity.sol";

contract PlaceSystem is System {
  /**
   * @dev place hero to borad, make it a piece
   * @param index index of hero in inventory
   * @param x coordinate x to place
   * @param y coordinate y to place
   */
  function placeToBoard(
    uint256 index,
    uint32 x,
    uint32 y
  ) public onlyWhenGamePreparing returns (uint32 creatureId, uint32 tier) {
    address player = _msgSender();

    // check whether x,y is valid
    checkCorValidity(player, x, y);

    uint64 hero = IWorld(_world()).popInventoryByIndex(player, index);
    (creatureId, tier) = IWorld(_world()).decodeHero(hero);

    IWorld(_world()).addPieceUncheckCoord(player, PieceData(creatureId, uint8(tier), x, y));
  }

  /**
   * @param index index of piece in pieces
   * @param x coordinate x to place
   * @param y coordinate y to place
   */
  function changePieceCoordinate(uint256 index, uint32 x, uint32 y) public onlyWhenGamePreparing {
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
    PieceInBattle.setX(pieceKeyForEnemy, GameConfig.getLength() * 2 - 1 - x);
    PieceInBattle.setY(pieceKeyForEnemy, y);
  }

  /**
   * @dev
   * @param index index of piece in piece
   */
  function placeBackInventory(uint256 index) public onlyWhenGamePreparing {
    address player = _msgSender();

    // delete piece and piece in battle on both of player board and his opponent board
    PieceData memory pd = IWorld(_world()).deletePieceByIndex(player, index);

    /// @dev add to inventory
    // check whether inventory is full
    require(Player.lengthInventory(player) < GameConfig.getInventorySlotNum(), "inventory full");


    Player.pushInventory(player, IWorld(_world()).encodeHero(pd.creature, pd.tier));
  }

  function checkCorValidity(address player, uint32 x, uint32 y) public view {
    // check x, y validity
    require(x < GameConfig.getLength(), "x too large");
    require(y < GameConfig.getWidth(), "y too large");

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

  function _checkGamePreparing() internal view {
    address player = _msgSender();
    uint32 gameId = Player.getGameId(player);
    // check game status
    require(Game.getStatus(gameId) == GameStatus.PREPARING, "Game not in prepare");
  }

  modifier onlyWhenGamePreparing() {
    _checkGamePreparing();
    _;
  }
}

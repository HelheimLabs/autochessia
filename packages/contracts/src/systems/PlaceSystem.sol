// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {System} from "@latticexyz/world/src/System.sol";
import {Board, PlayerGlobal, Player, Game, GameConfig, HeroData, Hero, Piece} from "../codegen/Tables.sol";
import {GameStatus} from "../codegen/Types.sol";
import {Utils} from "../library/Utils.sol";
import {IWorld} from "src/codegen/world/IWorld.sol";
import {getUniqueEntity} from "@latticexyz/world/src/modules/uniqueentity/getUniqueEntity.sol";

contract PlaceSystem is System {
    /**
     * @dev place hero to borad, make it a piece
     * @param index index of hero in inventory
     * @param x coordinate x to place
     * @param y coordinate y to place
     */
    function placeToBoard(uint256 index, uint32 x, uint32 y)
        public
        onlyWhenGamePreparing
        returns (uint32 creatureId, uint32 tier)
    {
        address player = _msgSender();

        require(Player.getTier(player) >= Player.lengthHeroes(player), "Board is full");

        // check whether x,y is valid
        checkCorValidity(player, x, y);

        uint64 hero = Utils.popInventoryByIndex(player, index);
        (creatureId, tier) = IWorld(_world()).decodeHero(hero);

        /// @dev create piece for play
        bytes32 pieceKey = getUniqueEntity();

        // create piece
        Hero.set(pieceKey, creatureId, uint8(tier), x, y);
        // add piece to player
        Player.pushHeroes(player, pieceKey);
    }

    /**
     * @param index index of hero in Player.heroes
     * @param x coordinate x to place
     * @param y coordinate y to place
     */
    function changeHeroCoordinate(uint256 index, uint32 x, uint32 y) public onlyWhenGamePreparing {
        address player = _msgSender();

        checkCorValidity(player, x, y);

        bytes32 pieceKeyForPlayer = Player.getItemHeroes(player, index);

        // update hero on board
        Hero.setX(pieceKeyForPlayer, x);
        Hero.setY(pieceKeyForPlayer, y);
    }

    /**
     * @dev
     * @param index index of hero in Player.heroes
     */
    function placeBackInventory(uint256 herosIndex) public onlyWhenGamePreparing returns (uint256 invIdx) {
        address player = _msgSender();

        // delete hero
        HeroData memory pd = Utils.deleteHeroByIndex(player, herosIndex);

        /// @dev add to inventory

        // find empty index
        invIdx = Utils.getFirstInventoryEmptyIdx(player);

        // update in inventory
        Player.updateInventory(player, invIdx, IWorld(_world()).encodeHero(pd.creatureId, pd.tier));
    }

    /**
     * @dev place back hero to a specific inventory slot
     * @param herosIndex index of hero in Player.heroes
     * @param invIdx inventory index for hero to place
     */
    function placeBackInventoryAndSwap(uint256 herosIndex, uint256 invIdx) public onlyWhenGamePreparing {
        swapInventory(placeBackInventory(herosIndex), invIdx);
    }

    /**
     * @dev
     * @param index index of hero in Player.heroes
     */
    function swapInventory(uint256 fromIndex, uint256 toIndex) public onlyWhenGamePreparing {
        address player = _msgSender();

        uint8 maxIdx = GameConfig.getInventorySlotNum(0) - 1;
        require(fromIndex < maxIdx, "index out of range");
        require(toIndex < maxIdx, "index out of range");

        // get value
        uint64 fromHero = Player.getItemInventory(player, fromIndex);
        uint64 toHero = Player.getItemInventory(player, toIndex);

        // set both
        Player.updateInventory(player, fromIndex, toHero);
        Player.updateInventory(player, toIndex, fromHero);
    }

    function checkCorValidity(address player, uint32 x, uint32 y) public view {
        // check x, y validity
        require(x < GameConfig.getLength(0), "x too large");
        require(y < GameConfig.getWidth(0), "y too large");

        // check whether (x,y) is empty
        uint64 cor = IWorld(_world()).encodeCor(x, y);
        // loop piece to check whether is occupied
        for (uint256 i = 0; i < Player.lengthHeroes(player); i++) {
            bytes32 key = Player.getItemHeroes(player, i);
            require(cor != IWorld(_world()).encodeCor(Hero.getX(key), Hero.getY(key)), "this location is not empty");
        }
    }

    function _checkGamePreparing() internal view {
        address player = _msgSender();
        uint32 gameId = PlayerGlobal.getGameId(player);
        // check game status
        require(Game.getStatus(gameId) == GameStatus.PREPARING, "Game not in prepare");
    }

    modifier onlyWhenGamePreparing() {
        _checkGamePreparing();
        _;
    }
}

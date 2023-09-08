// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "src/codegen/world/IWorld.sol";
import {PlayerGlobal, Player, Game, GameConfig, ShopConfig} from "src/codegen/Tables.sol";
import {PlayerStatus} from "src/codegen/Types.sol";
import {Utils} from "src/library/Utils.sol";

contract ShopSystem is System {
    /**
     * @notice this system is open
     */

    /**
     * @dev lock hero altar
     */
    function lockHeroAltar() public onlyInGame {
        Player.setLocked(_msgSender(), true);
    }

    /**
     * @dev unlock hero altar
     */
    function unlockHeroAltar() public onlyInGame {
        Player.setLocked(_msgSender(), false);
    }

    /**
     * @dev buy referesh hero
     */
    function buyRefreshHero() public onlyInGame {
        address player = _msgSender();

        require(!Player.getLocked(player), "ShopSystem: hero shop is locked");

        // charge coin
        Player.setCoin(player, Player.getCoin(player) - ShopConfig.getRefreshPrice(0));

        // refersh heros
        IWorld(_world()).refreshHeroes(player);
    }

    /**
     * @dev buy hero, from shop to inventory
     * @param index the index of hero in shop. start from 0
     */
    function buyHero(uint256 index) public onlyInGame returns (uint256 creatureIndex, uint256 tier) {
        address player = _msgSender();

        require(index < GameConfig.getInventorySlotNum(0), "index too large");

        // get hero info
        uint256 hero = Player.getItemHeroAltar(player, index);
        require(hero > 0, "empty hero altar slot");

        // set the index as empty
        Player.updateHeroAltar(player, index, 0);

        (tier, creatureIndex) = Utils.decodeHero(hero);

        // charge coin
        uint256 price = Utils.getHeroRarity(hero);
        uint256 balance = Player.getCoin(player);
        require(balance >= price, "insufficient coin");
        Player.setCoin(player, uint32(balance - price));

        // recuit the hero
        _recruitAnHero(player, hero);
    }

    /**
     * @dev sell hero in inventory
     * @param index index in inventory, start from 0
     */
    function sellHero(uint32 index) public onlyInGame {
        address player = _msgSender();

        uint256 hero = Player.getItemInventory(player, index);
        require(hero != 0, "no hero in this slot");

        uint256 tier = Utils.getHeroTier(hero);
        uint256 rarity = Utils.getHeroRarity(hero);

        // refund coin
        Player.setCoin(player, Player.getCoin(player) + uint32((3 ** tier) * rarity));

        // remove from inventory, set this as empty
        Utils.popInventoryByIndex(player, index);
    }

    /**
     * @dev player buy exp
     */
    function buyExp() public onlyInGame {
        address player = _msgSender();

        // charge coin
        Player.setCoin(player, Player.getCoin(player) - ShopConfig.getExpPrice(0));

        // increase exp
        // fix exp with 4
        IWorld(_world()).addExperience(player, 4);
    }

    function _recruitAnHero(address _player, uint256 _hero) internal returns (uint256 hero) {
        bool merged;
        (merged, hero) = IWorld(_world()).merge(_player, _hero);

        if (merged) {
            return _recruitAnHero(_player, hero);
        }

        uint256 index = Utils.getFirstInventoryEmptyIdx(_player);

        // set index in inventory
        Player.updateInventory(_player, index, uint24(_hero));
    }

    function _checkPlayerInGame() internal view {
        address player = _msgSender();
        // check player status
        require(PlayerGlobal.getStatus(player) == PlayerStatus.INGAME, "Player not in game");
    }

    modifier onlyInGame() {
        _checkPlayerInGame();
        _;
    }
}

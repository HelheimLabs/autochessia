// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "src/codegen/world/IWorld.sol";
import { Player, GameConfig, ShopConfig } from "src/codegen/Tables.sol";

contract ShopSystem is System {
  /**
   * @notice this system is open
   */

  /**
   * @dev buy referesh hero
   */
  function buyRefreshHero() public {
    address player = _msgSender();

    // charge coin
    Player.setCoin(player, Player.getCoin(player) - ShopConfig.getRefreshPrice());

    // refersh heros
    IWorld(_world()).refreshHeros(player);
  }

  /**
   * @dev buy hero, from shop to inventory
   * @param index the index of hero in shop. start from 0
   */
  function buyHero(uint256 index) public returns (uint32 creatureId, uint32 tier) {
    address player = _msgSender();

    // check inventory not full
    require(Player.lengthInventory(player) < GameConfig.getInventorySlotNum(), "Inventory full");

    // hero info
    uint64 hero = Player.getItemHeroAltar(player, index);

    // charge coin
    (creatureId, tier) = IWorld(_world()).decodeHero(hero);
    Player.setCoin(player, Player.getCoin(player) - ShopConfig.getItemTierPrice(tier));

    // add to inventory
    Player.pushInventory(player, hero);

    // remove from shop, two step
    // 1. swap bought one with last one
    Player.updateHeroAltar(player, index, Player.getItemHeroAltar(player, Player.lengthHeroAltar(player)));
    // 2. pop the last one
    Player.popHeroAltar(player);
  }

  /**
   * @dev sell hero in inventory
   * @param index index in inventory, start from 0
   */
  function sellHero(uint32 index) public {
    address player = _msgSender();

    uint64 hero = Player.getItemInventory(player, index);

    uint32 tier = IWorld(_world()).decodeHeroToTier(hero);

    // refund coin
    Player.setCoin(player, Player.getCoin(player) + ShopConfig.getItemTierPrice(tier));

    // remove from inventory
    // 1. swap sold one with last one
    Player.updateInventory(player, index, Player.getItemInventory(player, Player.lengthInventory(player)));

    // 2. pop inventory
    Player.popInventory(player);
  }

  /**
   * @dev player buy exp
   */
  function buyExp() public {
    address player = _msgSender();

    // charge coin
    Player.setCoin(player, Player.getCoin(player) - ShopConfig.getExpPrice());

    // increase exp
    // fix exp with 4
    IWorld(_world()).addExperience(player, 4);
  }
}

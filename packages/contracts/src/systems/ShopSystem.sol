// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "src/codegen/world/IWorld.sol";
import { Player, Game, GameConfig, ShopConfig } from "src/codegen/Tables.sol";
import { PlayerStatus } from "src/codegen/Types.sol";

contract ShopSystem is System {
  /**
   * @notice this system is open
   */

  /**
   * @dev buy referesh hero
   */
  function buyRefreshHero() public onlyInGame {
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
  function buyHero(uint256 index) public onlyInGame returns (uint32 creatureId, uint32 tier) {
    address player = _msgSender();

    // pop hero info
    uint64 hero = IWorld(_world()).popHeroAltarByIndex(player, index);

    // charge coin
    (, tier) = IWorld(_world()).decodeHero(hero);
    Player.setCoin(player, Player.getCoin(player) - ShopConfig.getItemTierPrice(tier));
    
    // recuit the hero
    IWorld(_world()).decodeHero(_recruitAnHero(player, hero));
  }

  /**
   * @dev sell hero in inventory
   * @param index index in inventory, start from 0
   */
  function sellHero(uint32 index) public onlyInGame {
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
  function buyExp() public onlyInGame {
    address player = _msgSender();

    // charge coin
    Player.setCoin(player, Player.getCoin(player) - ShopConfig.getExpPrice());

    // increase exp
    // fix exp with 4
    IWorld(_world()).addExperience(player, 4);
  }

  function _recruitAnHero(address _player, uint64 _hero) internal returns (uint64 hero) {
    bool merged;
    (merged, hero) = IWorld(_world()).merge(_player, _hero);

    if (merged) {
      return _recruitAnHero(_player, hero);
    }

    // check inventory not full
    require(Player.lengthInventory(_player) < GameConfig.getInventorySlotNum(), "Inventory full");
    // add to inventory
    Player.pushInventory(_player, hero);
  }

  function _checkPlayerInGame() internal view {
    address player = _msgSender();
    // check player status
    require(Player.getStatus(player) == PlayerStatus.INGAME, "Player not in game");
  }

  modifier onlyInGame() {
    _checkPlayerInGame();
    _;
  }
}

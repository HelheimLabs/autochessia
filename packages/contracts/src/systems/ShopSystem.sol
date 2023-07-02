// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "src/codegen/world/IWorld.sol";
import { Player, GameConfig, ShopConfig } from "src/codegen/Tables.sol";

contract ShopSystem is System {
  function buyRefreshHero() public {
    address player = _msgSender();

    // deduct coin
    Player.setCoin(player, Player.getCoin(player) - ShopConfig.getRefreshPrice());

    // refersh heros
    IWorld(_world()).refreshHeros(player);
  }
}

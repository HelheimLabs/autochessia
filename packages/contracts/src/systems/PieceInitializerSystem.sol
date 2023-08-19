// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "../codegen/world/IWorld.sol";
import {Creature, CreatureData, GameConfig, CreatureConfig} from "../codegen/Tables.sol";
import {Hero, HeroData} from "../codegen/Tables.sol";
import {Piece} from "../codegen/Tables.sol";
import {Player} from "../codegen/Tables.sol";
import {getUniqueEntity} from "@latticexyz/world/src/modules/uniqueentity/getUniqueEntity.sol";

contract PieceInitializerSystem is System {
    function initPieces(address _player, bool _atHome) public returns (bytes32[] memory ids) {
        bytes32[] memory heroIds = Player.getHeroes(_player);
        uint256 num = heroIds.length;
        ids = new bytes32[](num);
        for (uint256 i; i < num; ++i) {
            bytes32 heroId = heroIds[i];
            bytes32 pieceId = _atHome ? heroId : getUniqueEntity();
            HeroData memory hero = Hero.get(heroId);
            CreatureData memory data = Creature.get(hero.creatureId);
            uint8 tier = hero.tier;
            uint32 health =
                tier > 0 ? (data.health * CreatureConfig.getItemHealthAmplifier(0, tier - 1)) / 100 : data.health;
            Piece.set(
                pieceId,
                _atHome ? uint8(hero.x) : uint8(GameConfig.getLength(0) * 2 - 1 - hero.x),
                uint8(hero.y),
                tier,
                health,
                tier > 0 ? (data.attack * CreatureConfig.getItemAttackAmplifier(0, tier - 1)) / 100 : data.attack,
                uint8(data.range),
                tier > 0 ? (data.defense * CreatureConfig.getItemDefenseAmplifier(0, tier - 1)) / 100 : data.defense,
                data.speed,
                uint8(data.movement),
                health,
                hero.creatureId
            );
            ids[i] = pieceId;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct Damage {
    DamageType t;
    uint8 critChance;
    uint64 critValue; // base 100
    uint64 power;
}

import "forge-std/Test.sol";
import {DamageType} from "src/codegen/common.sol";

library DamageLib {
    function genDamage(DamageType _type, uint256 _critChance, uint256 _critValue, uint256 _power)
        internal
        pure
        returns (uint256 dmg)
    {
        dmg += uint8(_type);
        dmg <<= 8;
        dmg += uint8(_critChance);
        dmg <<= 64;
        dmg += uint64(_critValue);
        dmg <<= 64;
        dmg += uint64(_power);
    }

    function _parseDamage(uint256 _dmg) internal pure returns (Damage memory dmg) {
        dmg.power = uint64(_dmg);
        _dmg >>= 64;
        dmg.critValue = uint64(_dmg);
        _dmg >>= 64;
        dmg.critChance = uint8(_dmg);
        _dmg >>= 8;
        dmg.t = DamageType(uint8(_dmg));
    }

    function getDmgValue(uint256 _dmg, uint256 _rand) internal view returns (uint256 value) {
        Damage memory dmg = _parseDamage(_dmg);
        if ((_rand % 100) < dmg.critChance) {
            value = (dmg.critValue * dmg.power) / 100;
            console.log("    piece crit, crit chance %d, damage %d", dmg.critChance, value);
        } else {
            value = dmg.power;
        }
    }
}

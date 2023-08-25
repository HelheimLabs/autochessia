// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {MudTest} from "@latticexyz/store/src/MudTest.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";

contract AutoBattleSystemTest is MudTest {
    IWorld public world;

    function setUp() public override {
        super.setUp();
        world = IWorld(worldAddress);
    }

    function testVerify() public {
        bytes32 hash = bytes32(uint256(81237236374261549733610421423675660302593437835845686599988697315859357538687));
        bool res = world.verifyPasswordProof(
            [
                7308847571902260814663243248400126121756279162897803606663254410744212596741,
                3063664984043259489542544053763319632493331641391010898525063209542237535242
            ],
            [
                [
                    11483110715722374933234405719280629408858821276398352151120355605019675333991,
                    19924671363283338065554015896033375553515849790672758709433767196325244720557
                ],
                [
                    11100948652231520342636536733319762922091167778048311115663846726195363499863,
                    13729657473833866987259359664095904038925415269493181567716246121972168380935
                ]
            ],
            [
                9164534137446842740788950177858479436217479067790693216697768264441946652625,
                8228051669753864808269039696861172492320990233318881119630227593720076350728
            ],
            [uint256(hash) >> 128, uint128(uint256(hash)), 1149426209652027018119632776741807757396528378306]
        );
        console.log(uint256(hash) >> 128);
        console.log(uint128(uint256(hash)));
        assertTrue(res);
    }
}

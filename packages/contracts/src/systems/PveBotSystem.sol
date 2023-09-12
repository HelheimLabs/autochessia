// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "../codegen/world/IWorld.sol";
import {Creature, CreatureData, GameConfig, ShopConfig, Rank} from "../codegen/Tables.sol";
import {Board, BoardData} from "../codegen/Tables.sol";
import {Hero, HeroData} from "../codegen/Tables.sol";
import {Piece, PieceData} from "../codegen/Tables.sol";
import {GameRecord, Game, GameData} from "../codegen/Tables.sol";
import {PlayerGlobal, Player} from "../codegen/Tables.sol";
import {GameStatus, BoardStatus, PlayerStatus} from "../codegen/Types.sol";
import {Coordinate as Coord} from "cement/utils/Coordinate.sol";
import {RTPiece} from "../library/RunTimePiece.sol";
import {Utils} from "../library/Utils.sol";

contract PveBotSystem is System {
    function _getHeroIdx(address player) internal returns (bytes32 idx) {
        uint32 i = Player.getHeroOrderIdx(player);

        idx = bytes32((uint256(uint160(player)) << 96) + ++i);

        Player.setHeroOrderIdx(player, i);
    }

    // TODO Upgrade piece with round

    function _botSetPiece(uint32 _gameId, address _player) public {
        uint32 round = Game.getRound(_gameId);

        if (round % 2 == 1) {
            uint256 r = IWorld(_world()).getRandomNumberInGame(_gameId);

            address bot = Utils.getBotAddress(_player);

            bytes32 pieceKey = _getHeroIdx(bot);

            IWorld(_world()).refreshHeroes(bot);

            uint24 creatureId = Player.getItemHeroAltar(bot, r % 5);
            r >>= 8;

            uint32 x = uint32(r % 4);
            r >>= 8;

            uint32 y = uint32((r / 4) % 8);

            bool hasErr = checkCorValidity(bot, x, y);

            if (hasErr) {
                _botSetPiece(_gameId, _player);
            } else {
                // create piece
                Hero.set(pieceKey, creatureId, x, y);
                // add piece to player
                Player.pushHeroes(bot, pieceKey);
                // }
            }
        }
    }

    function checkCorValidity(address player, uint32 x, uint32 y) internal view returns (bool hasErr) {
        // check x, y validity
        require(x < GameConfig.getLength(0), "x too large");
        require(y < GameConfig.getWidth(0), "y too large");

        // check whether (x,y) is empty
        uint256 cor = Coord.compose(x, y);
        // loop piece to check whether is occupied
        for (uint256 i = 0; i < Player.lengthHeroes(player); i++) {
            bytes32 key = Player.getItemHeroes(player, i);
            HeroData memory hero = Hero.get(key);
            if (cor != Coord.compose(hero.x, hero.y)) {
                hasErr = true;
            }
            // require(cor != Coord.compose(hero.x, hero.y), "this location is not empty");
        }

        hasErr = false;
    }
}

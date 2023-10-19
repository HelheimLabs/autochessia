// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {SystemSwitch} from "@latticexyz/world-modules/src/utils/SystemSwitch.sol";

import {IWorld} from "../codegen/world/IWorld.sol";
import {GameConfig} from "../codegen/index.sol";
import {Player, Board, Creature, Hero, Piece} from "../codegen/index.sol";
import {CreatureData, PieceData} from "../codegen/index.sol";
import {PQ, PriorityQueue} from "cement/utils/PQ.sol";
import {JPS} from "cement/pathfinding/JPS.sol";
import {Coordinate as Coord} from "cement/utils/Coordinate.sol";
import {PieceActionLib} from "../library/PieceActionLib.sol";
import {RTPiece, RTPieceUtils} from "../library/RunTimePiece.sol";
import {EffectCache, EffectLib} from "../library/EffectLib.sol";
import {Utils} from "../library/Utils.sol";

contract PieceDecisionMakeSystem is System {
    using PQ for PriorityQueue;

    uint32 private constant ATTACK_MODE_KILL_FIRST = (100 << 16) + 100;

    function startBattle(address _player) public returns (uint8 winner, uint256 damageTaken) {
        // generate and align pieces
        (RTPiece[] memory pieces, EffectCache memory cache) = _genAndAlignPieces(_player);
        uint256 num = pieces.length;
        if (num == 0) {
            return (3, 0);
        }

        // generate map
        uint8[][] memory map =
            abi.decode(SystemSwitch.call(abi.encodeCall(IWorld(_world())._genMap, (pieces))), (uint8[][]));

        // init simulator
        (pieces, cache) = abi.decode(
            SystemSwitch.call(abi.encodeCall(IWorld(_world()).initSimulator, (pieces, cache))), (RTPiece[], EffectCache)
        );

        for (uint256 i; i < num; ++i) {
            uint256 action = decide(pieces, map, i);
            (pieces, map, cache) = abi.decode(
                SystemSwitch.call(abi.encodeCall(IWorld(_world()).doAction, (pieces, map, cache, action))),
                (RTPiece[], uint8[][], EffectCache)
            );
        }

        // close simulator
        pieces =
            abi.decode(SystemSwitch.call(abi.encodeCall(IWorld(_world()).closeSimulator, (pieces, cache))), (RTPiece[]));

        // end turn, update pieces
        SystemSwitch.call(abi.encodeCall(IWorld(_world())._updatePieces, (pieces)));
        (winner, damageTaken) =
            abi.decode(SystemSwitch.call(abi.encodeCall(IWorld(_world())._getWinner, (pieces))), (uint8, uint256));
    }

    function decide(RTPiece[] memory _pieces, uint8[][] memory _map, uint256 _index)
        internal
        returns (uint256 action)
    {
        RTPiece memory piece = _pieces[_index];
        if (piece.health == 0) {
            return 0;
        }

        console.log("piece %x start turn, (%d,%d)", uint256(piece.id), piece.x, piece.y);

        // PriorityQueue memory optionsQueue = PQ.New(_pieces.length);

        // todo skill
        // exploreSkillOption(_map, optionsQueue, piece, _pieces, SKILL_MODE_KILL_FIRST);

        // exploreAttackOption(_map, optionsQueue, piece, _pieces, ATTACK_MODE_KILL_FIRST);

        // action = optionsQueue.PopTask();

        if (!piece.canAct()) {
            console.log("    piece can not act, skip");
            return action;
        }
        if (piece.canCast()) {
            action = exploreSkill();
            if (action != 0) {
                return action;
            }
        }
        if (piece.canAttack()) {
            action = abi.decode(
                SystemSwitch.call(abi.encodeCall(IWorld(_world()).exploreAttack, (_pieces, _index))), (uint256)
            );
            if (action != 0) {
                return action;
            }
        }

        if (piece.canMove()) {
            action = abi.decode(
                SystemSwitch.call(abi.encodeCall(IWorld(_world()).exploreMove, (_map, _pieces, _index))), (uint256)
            );
            if (action != 0) {
                return action;
            }
        }
    }

    // todo
    function exploreSkill() internal pure returns (uint256 action) {
        return 0;
    }

    /**
     * @notice generate a sorted array of run-time pieces.
     */
    function _genAndAlignPieces(address _player)
        internal
        view
        returns (RTPiece[] memory pieces, EffectCache memory cache)
    {
        bytes32[] memory ids1 = Board.getPieces(_player);
        bytes32[] memory ids2 = Board.getEnemyPieces(_player);
        uint256 num1 = ids1.length;
        uint256 num2 = ids2.length;
        uint256 length = num1 + num2;
        pieces = new RTPiece[](length);
        cache = EffectLib.NewEffectCache(length);
        for (uint256 i; i < length; ++i) {
            bytes32 id = i < num1 ? ids1[i] : ids2[i - num1];
            PieceData memory piece = Piece.get(id);
            if (piece.health == 0) {
                continue;
            }
            CreatureData memory data = Creature.get(piece.creatureId);
            RTPiece memory rtPiece = RTPieceUtils.NewRTPiece(id, i < num1 ? 0 : 1, 0, piece, data);
            // apply effect modification
            rtPiece.updateAttribute(cache);
            // insert sorting according to speed in ascending direction
            uint256 j = i;
            while ((j > 0) && (pieces[j - 1].speed > rtPiece.speed)) {
                pieces[j] = pieces[j - 1];
                --j;
            }
            pieces[j] = rtPiece;
        }
        for (uint256 i; i < length; ++i) {
            pieces[i].index = uint8(i);
        }
    }

    // function _findBestAttackPosition(uint8[][] memory _map, RTPiece memory _piece, RTPiece memory _target)
    //     internal
    //     view
    //     returns (uint256 dst, uint256 X, uint256 Y)
    // {
    //     int256 left;
    //     int256 right;
    //     int256 directionX = 1;
    //     {
    //         uint256 x = _target.x;
    //         uint256 range = _piece.range;
    //         left = x > range ? int256(x - range) : int256(0);
    //         uint256 length = _map.length;
    //         right = (x + range) < length ? int256(x + range) : int256(length - 1);
    //         if (_piece.x > x) {
    //             directionX = -1;
    //             (left, right) = (right, left);
    //         }
    //     }

    //     int256 up;
    //     int256 down;
    //     int256 directionY = 1;
    //     {
    //         uint256 y = _target.y;
    //         uint256 range = _piece.range;
    //         down = y > range ? int256(y - range) : int256(0);
    //         uint256 width = _map[0].length;
    //         up = (y + range) < width ? int256(y + range) : int256(width - 1);
    //         if (_piece.y > y) {
    //             directionY = -1;
    //             (up, down) = (down, up);
    //         }
    //     }

    //     right += directionX;
    //     up += directionY;
    //     while (left != right) {
    //         int256 temp = down;
    //         while (down != up) {
    //             if (_map[uint256(left)][uint256(down)] == 0) {
    //                 uint256[] memory path = JPS.findPath(_map, _piece.x, _piece.y, uint256(left), uint256(down));
    //                 dst = path.length;
    //                 if (dst > 0) {
    //                     // console.log("    attack position (%d,%d), dst %d", left, down, dst);
    //                     // coord = path[dst];
    //                     --dst;
    //                     if (dst > _piece.movement) {
    //                         (X, Y) = Coord.decompose(path[_piece.movement]);
    //                     } else {
    //                         (X, Y) = Coord.decompose(path[dst]);
    //                     }
    //                     return (dst, X, Y);
    //                 }
    //             }
    //             down = down + directionY;
    //         }
    //         down = temp;
    //         left = left + directionX;
    //     }
    //     return (dst, X, Y);
    // }
}

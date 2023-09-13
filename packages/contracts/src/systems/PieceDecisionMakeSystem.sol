// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "../codegen/world/IWorld.sol";
import {GameConfig} from "../codegen/Tables.sol";
import {Player, Board, Creature, Hero, Piece} from "../codegen/Tables.sol";
import {CreatureData, PieceData} from "../codegen/Tables.sol";
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
        uint8[][] memory map = _genMap(pieces);

        // init simulator
        (pieces, cache) = IWorld(_world()).initSimulator(pieces, cache);

        for (uint256 i; i < num; ++i) {
            uint256 action = decide(pieces, map, i);
            (pieces, map, cache) = IWorld(_world()).doAction(pieces, map, cache, action);
        }

        // close simulator
        pieces = IWorld(_world()).closeSimulator(pieces, cache);

        // end turn, update pieces
        _updatePieces(pieces);
        (winner, damageTaken) = _getWinner(pieces);
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
            action = exploreAttack(_pieces, _index);
            if (action != 0) {
                return action;
            }
        }

        if (piece.canMove()) {
            action = exploreMove(_map, _pieces, _index);
            if (action != 0) {
                return action;
            }
        }
    }

    // todo
    function exploreSkill() internal returns (uint256 action) {
        return 0;
    }

    function exploreAttack(RTPiece[] memory _pieces, uint256 _index) internal returns (uint256 action) {
        uint256 length = _pieces.length;
        PriorityQueue memory pq = PQ.New(length);
        RTPiece memory attacker = _pieces[_index];
        for (uint256 i; i < length; ++i) {
            RTPiece memory enemy = _pieces[i];
            if (enemy.health == 0 || enemy.owner == attacker.owner) {
                continue;
            }
            uint256 dist = Coord.distance(attacker.x, attacker.y, enemy.x, enemy.y);
            if (dist <= attacker.range) {
                console.log("    attackable piece %x, distance %d", uint256(enemy.id), dist);
                pq.AddTask(i, dist);
            }
        }
        if (!pq.IsEmpty()) {
            uint256 target = pq.PopTask();
            console.log("    attack piece %x", uint256(_pieces[target].id));
            return PieceActionLib.generateAttackAction(_index, target);
        }
        console.log("    no enemy in attack range");
    }

    function exploreMove(uint8[][] memory _map, RTPiece[] memory _pieces, uint256 _index)
        internal
        view
        returns (uint256 action)
    {
        uint256 length = _pieces.length;
        RTPiece memory attacker = _pieces[_index];
        PriorityQueue memory pq = PQ.New(length);
        _setToWalkable(_map, attacker.x, attacker.y);
        for (uint256 i; i < length; ++i) {
            RTPiece memory enemy = _pieces[i];
            if (enemy.health == 0 || enemy.owner == attacker.owner) {
                continue;
            }
            _setToWalkable(_map, enemy.x, enemy.y);
            (uint256 dst, uint256 moveTo) = _findPath(_map, attacker, enemy);
            if (dst > 0) {
                pq.AddTask(moveTo, dst);
            }
            _setToObstacle(_map, enemy.x, enemy.y);
        }
        _setToObstacle(_map, attacker.x, attacker.y);
        if (!pq.IsEmpty()) {
            (uint256 X, uint256 Y) = Coord.decompose(pq.PopTask());
            console.log("    move to (%d,%d)", X, Y);
            return PieceActionLib.generateMoveAction(_index, X, Y);
        }
        console.log("    no reachable enemy");
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

    function _genMap(RTPiece[] memory _pieces) internal view returns (uint8[][] memory map) {
        uint256 num = _pieces.length;
        uint256 length = GameConfig.getLength(0) * 2;
        uint256 width = GameConfig.getWidth(0);
        map = new uint8[][](length);
        for (uint256 i; i < length; ++i) {
            map[i] = new uint8[](width);
        }
        for (uint256 i; i < num; ++i) {
            RTPiece memory piece = _pieces[i];
            map[piece.x][piece.y] = 1;
        }
    }

    function _findPath(uint8[][] memory _map, RTPiece memory _piece, RTPiece memory _target)
        internal
        view
        returns (uint256 dst, uint256 nextPosition)
    {
        uint256[] memory path = JPS.findPath(_map, _piece.x, _piece.y, _target.x, _target.y);
        dst = path.length;
        if (dst > 1) {
            return (dst, path[1]);
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

    function _setToWalkable(uint8[][] memory _map, uint256 _x, uint256 _y) private pure {
        _map[_x][_y] = 0;
    }

    function _setToObstacle(uint8[][] memory _map, uint256 _x, uint256 _y) private pure {
        _map[_x][_y] = 1;
    }

    /**
     * @param winner: 0: nobody, 1: player1, 2：player2, 3: draw
     */
    function _getWinner(RTPiece[] memory _pieces) private returns (uint8 winner, uint256 damageTaken) {
        uint256 allyHPSum;
        uint256 enemyHPSum;
        uint256 num = _pieces.length;
        for (uint256 i; i < num; ++i) {
            RTPiece memory piece = _pieces[i];
            if (piece.health == 0) {
                continue;
            }
            if (piece.owner == 0) {
                allyHPSum += piece.health;
            } else {
                enemyHPSum += piece.health;
                damageTaken += piece.getTier() + 1;
            }
        }

        if (allyHPSum == 0 && enemyHPSum == 0) {
            return (3, damageTaken);
        }
        if (allyHPSum == 0) {
            return (2, damageTaken);
        }
        if (enemyHPSum == 0) {
            return (1, damageTaken);
        }
        return (0, 0);
    }

    function _updatePieces(RTPiece[] memory _pieces) internal {
        uint256 num = _pieces.length;
        for (uint256 i; i < num; ++i) {
            _pieces[i].writeBack();
        }
    }
}

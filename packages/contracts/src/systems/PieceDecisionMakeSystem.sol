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
import {PieceActionSimulator as PieceAction} from "../library/PieceActionSimulator.sol";
import {RTPiece, RTPieceUtils} from "../library/RunTimePiece.sol";
import {EffectCache, EffectLib} from "../library/EffectLib.sol";
import {Utils} from "../library/Utils.sol";

contract PieceDecisionMakeSystem is System {
    using PQ for PriorityQueue;

    uint32 private constant ATTACK_MODE_KILL_FIRST = (100 << 16) + 100;

    function startTurn(address _player) public returns (uint8 winner, uint256 damageTaken) {
        // generate and align pieces
        (RTPiece[] memory pieces, EffectCache memory cache) = _genAndAlignPieces(_player);
        uint256 num = pieces.length;
        if (num == 0) {
            return (3, 0);
        }

        // generate map
        uint8[][] memory map = _genMap(pieces);

        for (uint256 i; i < num; ++i) {
            uint256 action = decide(pieces, map, i);
            PieceAction.doAction(pieces, map, cache, action);
        }

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

        // PriorityQueue memory optionsQueue = PQ.New(_pieces.length);

        // todo skill
        // exploreSkillOption(_map, optionsQueue, piece, _pieces, SKILL_MODE_KILL_FIRST);

        // exploreAttackOption(_map, optionsQueue, piece, _pieces, ATTACK_MODE_KILL_FIRST);

        // action = optionsQueue.PopTask();
        if (!piece.canAct()) {
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
        RTPiece memory attacker = _pieces[_index];
        console.log("piece %d start turn, (%d,%d)", uint256(attacker.id), attacker.x, attacker.y);
        for (uint256 i; i < length; ++i) {
            RTPiece memory enemy = _pieces[i];
            if (enemy.health == 0 || enemy.owner == attacker.owner) {
                continue;
            }
            if (Coord.distance(attacker.x, attacker.y, enemy.x, enemy.y) <= attacker.range) {
                console.log("    attack piece %d at (%d,%d)", uint256(enemy.id), enemy.x, enemy.y);
                return PieceAction.generateAttackAction(_index, i);
            }
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
            return PieceAction.generateMoveAction(_index, X, Y);
        }
        console.log("    no reachable enemy");
    }

    // function exploreAttackOption(
    //   uint8[][] memory _map,
    //   PriorityQueue memory _pq,
    //   RTPiece memory _attacker,
    //   RTPiece[] memory _pieces,
    //   uint256 _mode
    // ) internal {
    //   (uint256 killScore, uint256 damageScore) = (_mode >> 16, uint16(_mode));
    //   // simulate attacking each enemies and add score in queue
    //   uint256 length = _pieces.length;
    //   console.log("piece %d start turn, (%d,%d)", uint256(_attacker.id), _attacker.x, _attacker.y);
    //   console.log("attack range %d", _attacker.range);
    //   _setToWalkable(_map, _attacker.x, _attacker.y);
    //   for (uint256 i; i < length; ++i) {
    //     RTPiece memory enemy = _pieces[i];
    //     if (enemy.health == 0 || enemy.owner == _attacker.owner) {
    //       continue;
    //     }
    //     // enemy in attack range
    //     if (Coord.distance(_attacker.x, _attacker.y, enemy.x, enemy.y) <= _attacker.range) {
    //       console.log("  piece %d in its attack range, at position (%d,%d)", uint256(enemy.id), enemy.x, enemy.y);
    //       uint256 damage = _attacker.attack > enemy.defense ? _attacker.attack - enemy.defense : 0;
    //       if (enemy.health > damage) {
    //         _pq.AddTask(
    //           PieceAction.generateAction(_attacker.x, _attacker.y, i, damage),
    //           type(uint256).max - ((damage * damageScore) / _attacker.attack)
    //         );
    //         continue;
    //       } else {
    //         _pq.AddTask(
    //           PieceAction.generateAction(_attacker.x, _attacker.y, i, damage),
    //           type(uint256).max - ((damage * damageScore) / _attacker.attack + killScore)
    //         );
    //         continue;
    //       }
    //     }
    //     // find attack position
    //     (uint256 dst, uint256 X, uint256 Y) = _findBestAttackPosition(_map, _attacker, enemy);
    //     if (dst > _attacker.movement) {
    //       // (uint256 X, uint256 Y) = Coord.decompose(coord);
    //       console.log("out of range, move to (%d,%d)", X, Y);
    //       _pq.AddTask(PieceAction.generateAction(X, Y, i, 0), type(uint256).max);
    //     } else {
    //       uint256 damage = _attacker.attack > enemy.defense ? _attacker.attack - enemy.defense : 0;
    //       if (enemy.health > damage) {
    //         // (uint256 X, uint256 Y) = Coord.decompose(coord);
    //         console.log("move to (%d,%d), cause damage %d", X, Y, damage);
    //         _pq.AddTask(
    //           PieceAction.generateAction(X, Y, i, damage),
    //           type(uint256).max - ((damage * damageScore) / _attacker.attack)
    //         );
    //         continue;
    //       } else {
    //         // (uint256 X, uint256 Y) = Coord.decompose(coord);
    //         _pq.AddTask(
    //           PieceAction.generateAction(X, Y, i, damage),
    //           type(uint256).max - ((damage * damageScore) / _attacker.attack + killScore)
    //         );
    //         continue;
    //       }
    //     }
    //   }
    //   _setToObstacle(_map, _attacker.x, _attacker.y);
    // }

    // function _simulateAction(
    //   RTPiece[] memory _pieces,
    //   uint8[][] memory _map,
    //   EffectCache memory _cache,
    //   uint256 _action
    // ) internal view {
    //   if (_action == 0) {
    //     return;
    //   }
    //   Action memory action = PieceAction.parseAction(_action);
    //   RTPiece memory piece = _pieces[action.executorIndex];
    //   uint8 actionType = action.actionType;
    //   if (actionType == 1) {
    //     // todo cast the ability
    //   } else if (actionType == 2) {
    //     RTPiece memory target = _pieces[action.targetIndex];
    //     uint256 health = target.health;
    //     uint256 damage = action.value;
    //     if (health > damage) {
    //       target.health = uint32(health - damage);
    //     } else {
    //       target.health = 0;
    //       _setToWalkable(_map, target.x, target.y);
    //     }
    //     _pieces[action.targetIndex] = target;
    //   } else if (actionType == 3) {
    //     _setToWalkable(_map, piece.x, piece.y);
    //     (uint256 X, uint256 Y) = Coord.decompose(action.value);
    //     piece.x = uint8(X);
    //     piece.y = uint8(Y);
    //     _setToObstacle(_map, X, Y);
    //     _pieces[action.executorIndex] = piece;
    //   }
    // }

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
            RTPiece memory rtPiece = RTPiece({
                id: id,
                status: uint16(7 << 13),
                tier: uint8(Utils.getHeroTier(piece.creatureId)),
                owner: i < num1 ? 0 : 1,
                index: 0,
                x: piece.x,
                y: piece.y,
                health: piece.health,
                maxHealth: data.health,
                attack: data.attack,
                range: uint8(data.range),
                defense: data.defense,
                speed: data.speed,
                movement: uint8(data.movement),
                creatureId: piece.creatureId,
                effects: RTPieceUtils.sliceEffects(piece.effects)
            });
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
                damageTaken += piece.tier + 1;
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

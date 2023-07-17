// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
// import { MudV2Test } from "@latticexyz/std-contracts/src/test/MudV2Test.t.sol";
import { PQ, PriorityQueue } from "../src/library/PQ.sol";
import { Coordinate as Coord } from "../src/library/Coordinate.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { JPS } from "../src/library/JPS.sol";

contract JPSTest is Test {
    using PQ for PriorityQueue;
    
    uint8[][] map;
    uint256[][] field;
    IWorld public world;

    function setUp() public {
        // super.setUp();
        // world = IWorld(worldAddress);
        uint8[][] memory input = new uint8[][](5);
        input[0] = new uint8[](5);
        input[1] = new uint8[](5);
        input[2] = new uint8[](5);
        input[2][0] = 1;
        input[2][1] = 1;
        input[2][2] = 1;
        input[2][3] = 1;
        input[3] = new uint8[](5);
        input[4] = new uint8[](5);
        map = input;
        field = JPS.generateField(map);
    }

    function test_PQ() public {
        PriorityQueue memory pq = PQ.New(5);
        pq.AddTask(1,1);
        pq.AddTask(2,2);
        pq.AddTask(3,30);
        pq.AddTask(4,4);
        pq.AddTask(5,5);
        for (uint i; i < 5; ++i) {
            console.log("Pop task, data %d", pq.PopTask());
        }
    }

    function test_FieldIsGood() public {
        uint8[][] memory input = new uint8[][](3);
        input[0] = new uint8[](3);
        input[1] = new uint8[](3);
        input[1][1] = 1;
        input[2] = new uint8[](3);
        printInput(input);
        field = JPS.generateField(input);
        // check boundary
        assertTrue(field[0][3] == 1024);
        assertTrue(field[4][3] == 1024);
        assertTrue(field[3][0] == 1024);
        assertTrue(field[3][4] == 1024);
        // check the leftmost and lowest coordinate
        assertFalse(field[1][1] == 1024);
        // check the central obstacle
        assertTrue(field[2][2] == 1024);
    }

    function test_FindPath() public {
        uint8[][] memory input = new uint8[][](5);
        input[0] = new uint8[](5);
        input[1] = new uint8[](5);
        input[2] = new uint8[](5);
        input[2][0] = 1;
        input[2][1] = 1;
        input[2][2] = 1;
        input[2][3] = 1;
        input[3] = new uint8[](5);
        input[4] = new uint8[](5);
        uint256[] memory path = JPS.findPath(input, 0, 0, 4, 0);
        for (uint i; i < path.length; ++i) {
            (uint x, uint y) = Coord.decompose(path[i]);
            console.log("(%d,%d)", x, y);
        }
    }

    function printInput(uint8[][] memory _input) private view {
        for (uint i; i < 3; ++i) {
            console.log(" %d  %d  %d ", _input[0][2-i], _input[1][2-i], _input[2][2-i]);
        }
    } 
}
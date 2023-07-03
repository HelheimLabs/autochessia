// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Coordinate as Coord } from "../library/Coordinate.sol";
import { PQ, PriorityQueue } from "../library/PQ.sol";

contract JPSLibSystem is System {
    function findPath(
        uint256[][] memory _fieldInput, 
        uint256 _startX,
        uint256 _startY,
        uint256 _endX,
        uint256 _endY
    ) public view returns (uint256[] memory path) {
        // console.log("JPS find path from (%d, %d)", _startX, _startY);
        // console.log("              to   (%d, %d)", _endX, _endY);
        uint256[][] memory field = generateField(_fieldInput);
        uint256[] memory nativePath = findPath(field, Coord.compose(_startX+1, _startY+1), Coord.compose(_endX+1, _endY+1));
        uint256 length = nativePath.length;
        path = new uint256[](length);
        for (uint i; i < length; ++i) {
            path[i] = nativePath[i] - 257;
        }
    }

    /*
     * @note generate field with boundaries. obstacles are represented by 1024.
     */
    function generateField(uint256[][] memory _input) public view returns (uint256[][] memory field) {
        uint256 length = _input.length;
        require(length > 0, "invalid input");
        uint256 width = _input[0].length;
        require(width > 0, "invalid input");
        uint256 fieldL = length + 2;
        uint256 fieldW = width + 2;
        field = new uint256[][](fieldL);
        for (uint i; i < length; ++i) {
            uint256[] memory column = new uint256[](fieldW);
            // upper and lower boundarier 
            (column[0], column[width+1]) = (1024, 1024);
            uint256[] memory columnInput = _input[i];
            for (uint j; j < width; ++j) {
                if (columnInput[j] == 1) {
                    column[j+1] = 1024;
                }
            }
            field[i+1] = column;
        }
        
        // left and right boundaries
        field[0] = new uint256[](fieldW);
        field[fieldL-1] = new uint256[](fieldW);
        for (uint i; i < fieldW; ++i) {
            (field[0][i], field[fieldL-1][i]) = (1024, 1024);
        }
    }
    
    /*
     * @note find the path from start position to end position. Input coordinates must be incremented by 1 in order to fit into
     * the field with boudaries.
     */
    function findPath(
        uint256[][] memory _field, 
        uint256 _start,  
        uint256 _end
    ) internal view returns (uint256[] memory path) {
        require(fieldNotObstacle(_field, _start), "invalid input");
        require(fieldNotObstacle(_field, _end), "invalid input");
        require(_start != _end, "invalid input");
        uint256[][] memory source;
        PriorityQueue memory pq;
        {
            uint256 length = _field.length;
            uint256 width = _field[0].length;
            source = new uint256[][](length);
            for (uint i; i < length; ++i) {
                uint256[] memory tempArray = new uint256[](width);
                source[i] = tempArray;
            }
            pq = PQ.New(length*width);
        }
        
        queueJumptPoint(pq, _start, 0);

        while (!pq.IsEmpty()) {
            uint256 jp = dequeueJumptPoint(pq);
            if (jpsExploreCardinal(_field, source, pq, jp, _end, 1, 0) ||
                jpsExploreCardinal(_field, source, pq, jp, _end, -1, 0) || 
                jpsExploreCardinal(_field, source, pq, jp, _end, 0, 1) ||
                jpsExploreCardinal(_field, source, pq, jp, _end, 0, -1) ||
                jpsExploreDiagonal(_field, source, pq, jp, _end, 1, 1) ||
                jpsExploreDiagonal(_field, source, pq, jp, _end, 1, -1) ||
                jpsExploreDiagonal(_field, source, pq, jp, _end, -1, 1) ||
                jpsExploreDiagonal(_field, source, pq, jp, _end, -1, -1)) {
                return getPath(source, _start, _end);
            }
        }
    }

    function getPath(
        uint256[][] memory _source,
        uint256 _start,
        uint256 _end
    ) internal pure returns (uint256[] memory path) {
        uint256 length = _source.length;
        uint256 width = _source[0].length;
        uint256[] memory result = new uint256[](length*width);
        uint256 coordinate = _end;
        (uint256 x, uint256 y) = Coord.decompose(coordinate);
        uint256 i;
        while (coordinate != _start) {
            result[i++] = coordinate;
            coordinate = _source[x][y];
            (x, y) = Coord.decompose(coordinate);
        }
        path = new uint256[](i+1);
        path[0] = _start;
        for (uint j = 1; j <= i; ++j) {
            path[j] = result[i-j];
        }
    }

    function queueJumptPoint(PriorityQueue memory _pq, uint256 _coordinate, uint256 _priority) internal view {
        // // test
        // (uint256 x, uint256 y) = decomposeData(_coordinate);
        // console.log("jp %d, %d", x, y);
        _pq.AddTask(_coordinate, _priority);
    }

    function dequeueJumptPoint(PriorityQueue memory _pq) internal pure returns (uint256) {
        return _pq.PopTask();
    }

    function fieldNotObstacle(uint256[][] memory _field, uint256 _position) internal pure returns (bool) {
        (uint256 x, uint256 y) = Coord.decompose(_position);
        return _field[x][y] == 0;
    }

    /*
     * @note Explores field along the diagonal direction for JPS, starting at point (startX, startY)
     */
    function jpsExploreDiagonal(
        uint256[][] memory _field,
        uint256[][] memory _source,
        PriorityQueue memory _pq, 
        uint256 _start, 
        uint256 _end, 
        int256 _directionX, 
        int256 _directionY
    ) internal view returns (bool found) {
        (uint256 curX, uint256 curY) = Coord.decompose(_start);
        uint256 curC;

        while (true) {
            {
                uint256 preC = Coord.compose(curX, curY);
                uint256 curCost = _field[curX][curY] + 1;
                curX = uint256(int256(curX) + _directionX);
                curY = uint256(int256(curY) + _directionY);
                curC = Coord.compose(curX, curY); 
                // console.log("diagonal reach %d, %d", curX, curY);

                if (curC == _end) {
                    _field[curX][curY] = curCost;
                    _source[curX][curY] = preC;
                    return true;
                } else if (_field[curX][curY] == 0) {
                    _field[curX][curY] = curCost;
                    _source[curX][curY] = preC;
                } else {
                    return false;
                }
            }
            uint256 nextX = uint256(int256(curX) + _directionX);
            uint256 nextY = uint256(int256(curY) + _directionY);
            if (((_field[nextX][curY] == 1024) && (_field[nextX][nextY] < 1024)) ||
                ((_field[curX][curY+1] == 1024) && (_field[nextX][curY+1] < 1024)) ||
                ((_field[curX][curY-1] == 1024) && (_field[nextX][curY-1] < 1024))) {
                uint256 priority = _field[curX][curY] + Coord.distance(curC, _end);
                queueJumptPoint(_pq, curC, priority);
                return false;
            } else {
                // console.log("expand x, %d, %d", curX, curY);
                if (jpsExploreCardinal(_field, _source, _pq, curC, _end, _directionX, 0)) {
                    return true;
                }
            }

            if (((_field[curX][nextY] == 1024) && (_field[nextX][nextY] < 1024)) ||
                ((_field[curX+1][curY] == 1024) && (_field[curX+1][nextY] < 1024)) ||
                ((_field[curX-1][curY] == 1024) && (_field[curX-1][nextY] < 1024))) {
                uint256 priority = _field[curX][curY] + Coord.distance(curC, _end);
                queueJumptPoint(_pq, curC, priority);
                return false;
            } else {
                // console.log("expand y, %d, %d", curX, curY);
                if (jpsExploreCardinal(_field, _source, _pq, curC, _end, 0, _directionY)) {
                    return true;
                }
            }
        }
    }
    
    /*
     * @note Explores field along the cardinal direction for JPS, starting at point (startX, startY)
     */
    function jpsExploreCardinal(
        uint256[][] memory _field,
        uint256[][] memory _source,
        PriorityQueue memory _pq, 
        uint256 _start,
        uint256 _end, 
        int256 _directionX, 
        int256 _directionY
    ) internal view returns (bool found) {
        (uint256 curX, uint256 curY) = Coord.decompose(_start);
        uint256 curC;

        while (true) {
            {
                uint256 preC = Coord.compose(curX, curY);
                uint256 curCost = _field[curX][curY] + 1;
                curX = uint256(int256(curX) + _directionX);
                curY = uint256(int256(curY) + _directionY);
                curC = Coord.compose(curX, curY); 

                if (curC == _end) {
                    _field[curX][curY] = curCost;
                    _source[curX][curY] = preC;
                    return true;
                } else if (_field[curX][curY] == 0) {
                    _field[curX][curY] = curCost;
                    _source[curX][curY] = preC;
                } else {
                    return false;
                }
            }
            // console.log("cardinal reach %d, %d", curX, curY);
            uint256 priority = _field[curX][curY] + Coord.distance(curC, _end);
            // check neighbouring cells, i.e. check if curX, curX is a jump point.
            if (_directionX == 0) {
                uint256 nextY = uint256(int256(curY) + _directionY);
                if ((_field[curX+1][curY] == 1024) && (_field[curX+1][nextY] < 1024)) {
                    queueJumptPoint(_pq, curC, priority);
                    return false;
                }
                if ((_field[curX-1][curY] == 1024) && (_field[curX-1][nextY] < 1024)) {
                    queueJumptPoint(_pq, curC, priority);
                    return false;
                }
            } else if (_directionY == 0) {
                uint256 nextX = uint256(int256(curX) + _directionX);
                if ((_field[curX][curY+1] == 1024) && (_field[nextX][curY+1] < 1024)) {
                    queueJumptPoint(_pq, curC, priority);
                    return false;
                }
                if ((_field[curX][curY-1] == 1024) && (_field[nextX][curY-1] < 1024)) {
                    queueJumptPoint(_pq, curC, priority);
                    return false;
                }
            }
        }
    }
}
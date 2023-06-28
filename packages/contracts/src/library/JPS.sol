// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library JPS {
    struct PriorityQueue {
        uint256 num;
        uint256[] data;
        uint256[] priority;
    }

    function NewPQ(uint256 _length) internal pure returns (PriorityQueue memory) {
        return PriorityQueue({num: 0, data: new uint256[](_length), priority: new uint256[](_length)});
    }

    function PQIsEmpty(PriorityQueue memory _pq) internal pure returns (bool) {
        return _pq.num == 0;
    }

    function PQAddTask(PriorityQueue memory _pq, uint256 _data, uint256 _priority) internal pure {
        uint256[] memory data = _pq.data;
        uint256[] memory priority = _pq.priority;
        for (uint i = _pq.num; i >= 0; --i) {
            if (priority[i] < _priority) {
                priority[i+1] = priority[i];
                data[i+1] = data[i];
            } else {
                priority[i+1] = _priority;
                data[i+1] = _data;
                break;
            }
        }
        ++_pq.num;
        _pq.data = data;
        _pq.priority = priority;
    }

    function PQPopTask(PriorityQueue memory _pq) internal pure returns (uint256) {
        return _pq.data[_pq.num--];
    }

    function composeData(uint256 _x, uint256 _y) public pure returns (uint256) {
        return _x * 256 + _y;
    }

    function decomposeData(uint256 _data) public pure returns (uint256, uint256) {
        return (_data / 256, _data % 256);
    }

    /*
     * @note generate field with boundaries. obstacles are represented by 1024.
     */
    function generateField(uint256[][] calldata _input) public pure returns (uint256[][] memory field) {
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
        for (uint i; i < fieldW; ++i) {
            (field[0][i], field[fieldL-1][i]) = (1024, 1024);
        }
    }

    function fieldNotObstacle(uint256[][] memory _field, uint256 _position) public pure returns (bool) {
        (uint256 x, uint256 y) = decomposeData(_position);
        return _field[x][y] < 1024;
    }

    /*
     * @note find the path from start position to end position. Input coordinates must be incremented by 1 in order to fit into
     * the field with boudaries.
     */
    function findPath(
        uint256[][] memory _field, 
        uint256 _start,  
        uint256 _end
    ) public pure returns (uint256[] memory path) {
        require(fieldNotObstacle(_field, _start), "invalid input");
        require(fieldNotObstacle(_field, _end), "invalid input");
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
            pq = NewPQ(length*width);
        }
        
        queueJumptPoint(pq, _start, 0);

        bool foundPath;

        while (!PQIsEmpty(pq)) {
            uint256 jp = dequeueJumptPoint(pq);

            if (!foundPath) {
                foundPath = jpsExploreCardinal(_field, source, foundPath, pq, jp, _end, 1, 0);
                foundPath = jpsExploreCardinal(_field, source, foundPath, pq, jp, _end, -1, 0);
                foundPath = jpsExploreCardinal(_field, source, foundPath, pq, jp, _end, 0, 1);
                foundPath = jpsExploreCardinal(_field, source, foundPath, pq, jp, _end, 0, -1);

                foundPath = jpsExploreDiagonal(_field, source, foundPath, pq, jp, _end, 1, 1);
                foundPath = jpsExploreDiagonal(_field, source, foundPath, pq, jp, _end, 1, -1);
                foundPath = jpsExploreDiagonal(_field, source, foundPath, pq, jp, _end, -1, 1);
                foundPath = jpsExploreDiagonal(_field, source, foundPath, pq, jp, _end, -1, -1);
            } else {
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
        (uint256 x, uint256 y) = decomposeData(coordinate);
        uint256 i;
        while (coordinate != _start) {
            result[i++] = coordinate;
            coordinate = _source[x][y];
            (x, y) = decomposeData(coordinate);
        }
        path = new uint256[](i+1);
        path[0] = _start;
        for (uint j = 1; j <= i; ++j) {
            path[j] = result[i-j];
        }
    }

    function queueJumptPoint(PriorityQueue memory _pq, uint256 _coordinate, uint256 _priority) internal pure {
        PQAddTask(_pq, _coordinate, _priority);
    }

    function dequeueJumptPoint(PriorityQueue memory _pq) internal pure returns (uint256) {
        return PQPopTask(_pq);
    }

    /*
     * @note return max(abs(x1-x2), abs(y1-y2))
     */
    function distance(uint256 _from, uint256 _to) internal pure returns (uint256) {
        (uint256 x1, uint256 y1) = decomposeData(_from);
        (uint256 x2, uint256 y2) = decomposeData(_to);
        uint256 distX = x1 < x2 ? x2 - x1 : x1 - x2;
        uint256 distY = y1 < y2 ? y2 - y1 : y1 - y2;
        return distX < distY ? distY : distX;
    }

    /*
     * @note Explores field along the diagonal direction for JPS, starting at point (startX, startY)
     */
    function jpsExploreDiagonal(
        uint256[][] memory _field,
        uint256[][] memory _source,
        bool _foundPath,
        PriorityQueue memory _pq, 
        uint256 _start, 
        uint256 _end, 
        int256 _directionX, 
        int256 _directionY
    ) internal pure returns (bool) {
        if (_foundPath) {
            return true;
        }
        (uint256 curX, uint256 curY) = decomposeData(_start);
        uint256 curC;

        while (true) {
            {
                uint256 curCost = _field[curX][curY] + 1;
                curX = uint256(int256(curX) + _directionX);
                curY = uint256(int256(curY) + _directionY);
                curC = composeData(curX, curY); 

                if (_field[curX][curY] == 0) {
                    _field[curX][curY] = curCost;
                    _source[curX][curY] = _start;
                } else if (curC == _end) {
                    _field[curX][curY] = curCost;
                    _source[curX][curY] = _start;
                    return true;
                } else {
                    return _foundPath;
                }
            }
            uint256 nextX = uint256(int256(curX) + _directionX);
            uint256 nextY = uint256(int256(curY) + _directionY);
            if ((_field[nextX][curY] == 1024) && (_field[nextX][nextY] < 1024)) {
                uint256 priority = _field[curX][curY] + distance(curC, _end);
                queueJumptPoint(_pq, curC, priority);
                return _foundPath;
            } else {
                _foundPath = jpsExploreCardinal(_field, _source, _foundPath, _pq, curC, _end, _directionX, 0);
            }

            if ((_field[curX][nextY] == 1024) && (_field[nextX][nextY] < 1024)) {
                uint256 priority = _field[curX][curY] + distance(curC, _end);
                queueJumptPoint(_pq, curC, priority);
                return _foundPath;
            } else {
                return jpsExploreCardinal(_field, _source, _foundPath, _pq, curC, _end, 0, _directionY);
            }
        }
    }
    
    /*
     * @note Explores field along the cardinal direction for JPS, starting at point (startX, startY)
     */
    function jpsExploreCardinal(
        uint256[][] memory _field,
        uint256[][] memory _source,
        bool _foundPath,
        PriorityQueue memory _pq, 
        uint256 _start,
        uint256 _end, 
        int256 _directionX, 
        int256 _directionY
    ) internal pure returns (bool) {
        if (_foundPath) {
            return true;
        }
        (uint256 curX, uint256 curY) = decomposeData(_start);
        uint256 curC;

        while (true) {
            {
                uint256 curCost = _field[curX][curY] + 1;
                curX = uint256(int256(curX) + _directionX);
                curY = uint256(int256(curY) + _directionY);
                curC = composeData(curX, curY); 
                ++curCost;

                if (_field[curX][curY] == 0) {
                    _field[curX][curY] = curCost;
                    _source[curX][curY] = curC;
                } else if (curC == _end) {
                    _field[curX][curY] = curCost;
                    _source[curX][curY] = curC;
                    return true;
                } else {
                    return _foundPath;
                }
            }
            uint256 priority = _field[curX][curY] + distance(curC, _end);
            // check neighbouring cells, i.e. check if curX, curX is a jump point.
            if (_directionX == 0) {
                uint256 nextY = uint256(int256(curY) + _directionY);
                if ((_field[curX+1][curY] == 1024) && (_field[curX+1][nextY] < 1024)) {
                    queueJumptPoint(_pq, curC, priority);
                    return _foundPath;
                }
                if ((_field[curX-1][curY] == 1024) && (_field[curX-1][nextY] < 1024)) {
                    queueJumptPoint(_pq, curC, priority);
                    return _foundPath;
                }
            } else if (_directionY == 0) {
                uint256 nextX = uint256(int256(curX) + _directionX);
                if ((_field[curX][curY+1] == 1024) && (_field[nextX][curY+1] < 1024)) {
                    queueJumptPoint(_pq, curC, priority);
                    return _foundPath;
                }
                if ((_field[curX][curY-1] == 1024) && (_field[nextX][curY-1] < 1024)) {
                    queueJumptPoint(_pq, curC, priority);
                    return _foundPath;
                }
            }
        }
    }
}
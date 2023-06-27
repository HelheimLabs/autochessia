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

    function generateField(uint256[][] calldata _input) public pure returns (uint256[][] memory field) {
        uint256 length = _input.length;
        require(length > 0, "invalid input");
        uint256 width = _input[0].length;
        require(width > 0, "invalid input");
        for (uint i; i < length; ++i) {
            uint256[] memory column = new uint256[](width);
            uint256[] memory columnInput = _input[i];
            for (uint j = 0; j < width; ++j) {
                if (columnInput[j] == 1) {
                    // use 1024 as obstacle
                    column[j] = 1024;
                }
            }
            field[i] = column;
        }
    }

    function findPath(
        uint256[][] memory _field, 
        uint256 _startX, 
        uint256 _startY, 
        uint256 _endX, 
        uint256 _endY
    ) public pure returns (uint256[] memory path) {
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
        
        queueJumptPoint(pq, _startX, _startY, 0);

        bool foundPath;

        while (!PQIsEmpty(pq)) {
            (uint256 x, uint256 y) = dequeueJumptPoint(pq);

            if (!foundPath) {
                foundPath = jpsExploreCardinal(_field, source, foundPath, pq, x, y, _endX, _endY, 1, 0);
                foundPath = jpsExploreCardinal(_field, source, foundPath, pq, x, y, _endX, _endY, 1, 0); // todo -1 0
                foundPath = jpsExploreCardinal(_field, source, foundPath, pq, x, y, _endX, _endY, 0, 1);
                foundPath = jpsExploreCardinal(_field, source, foundPath, pq, x, y, _endX, _endY, 0, 1); // todo 0 -1

                foundPath = jpsExploreDiagonal(_field, source, foundPath, pq, x, y, _endX, _endY, 1, 1);
                foundPath = jpsExploreDiagonal(_field, source, foundPath, pq, x, y, _endX, _endY, 1, 1); // todo 1 -1
                foundPath = jpsExploreDiagonal(_field, source, foundPath, pq, x, y, _endX, _endY, 1, 1); // todo -1 1
                foundPath = jpsExploreDiagonal(_field, source, foundPath, pq, x, y, _endX, _endY, 1, 1); // todo -1 -1
            } else {
                return getPath(source, _startX, _startY, _endX, _endY);
            }
        }
    }

    function getPath(
        uint256[][] memory _source,
        uint256 _startX,
        uint256 _startY,
        uint256 _endX,
        uint256 _endY
    ) internal pure returns (uint256[] memory path) {
        uint256 length = _source.length;
        uint256 width = _source[0].length;
        uint256[] memory result = new uint256[](length*width);
        uint256 startValue = composeData(_startX, _startY);
        uint256 value = composeData(_endX, _endY);
        uint256 x = _endX;
        uint256 y = _endY;
        uint256 i;
        while (startValue != value) {
            result[i++] = value;
            value = _source[x][y];
            (x, y) = decomposeData(value);
        }
        path = new uint256[](i+1);
        path[0] = startValue;
        for (uint j = 1; j <= i; ++j) {
            path[j] = result[i-j];
        }
    }

    function queueJumptPoint(PriorityQueue memory _pq, uint256 _x, uint256 _y, uint256 _priority) internal pure {
        PQAddTask(_pq, composeData(_x, _y), _priority);
    }

    function dequeueJumptPoint(PriorityQueue memory _pq) internal pure returns (uint256 x, uint256 y) {
        return decomposeData(PQPopTask(_pq));
    }

    /*
     * @note return max(abs(x1-x2), abs(y1-y2))
     */
    function distance(uint256 _x, uint256 _y, uint256 _targetX, uint256 _targetY) internal pure returns (uint256) {
        uint256 distX = _x < _targetX ? _targetX - _x : _x - _targetX;
        uint256 distY = _y < _targetY ? _targetY - _y : _y = _targetY;
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
        uint256 _startX, 
        uint256 _startY, 
        uint256 _endX, 
        uint256 _endY, 
        uint256 _directionX, 
        uint256 _directionY
    ) internal pure returns (bool) {
        if (_foundPath) {
            return true;
        }
        uint256 curX = _startX;
        uint256 curY = _startY;
        uint256 curCost = _field[_startX][_startY];

        while (true) {
            curX += _directionX;
            curY += _directionY;
            ++curCost;

            if (_field[curX][curY] == 0) {
                _field[curX][curY] = curCost;
                _source[curX][curY] = composeData(_startX, _startY);
            } else if ((curX == _endX) && (curY == _endY)) {
                _field[curX][curY] = curCost;
                _source[curX][curY] = composeData(_startX, _startY);
                return true;
            } else {
                return _foundPath;
            }

            uint256 priority = _field[curX][curY] + distance(curX, curY, _endX, _endY);
            if ((_field[curX+_directionX][curY] == 1024) && (_field[curX+_directionX][curY+_directionY] < 1024)) {
                queueJumptPoint(_pq, curX, curY, priority);
                return _foundPath;
            } else {
                _foundPath = jpsExploreCardinal(_field, _source, false, _pq, curX, curY, _endX, _endY, _directionX, 0);
            }

            if ((_field[curX][curY+_directionY] == 1024) && (_field[curX+_directionX][curY+_directionY] < 1024)) {
                queueJumptPoint(_pq, curX, curY, priority);
                return _foundPath;
            } else {
                return jpsExploreCardinal(_field, _source, _foundPath, _pq, curX, curY, _endX, _endY, 0, _directionY);
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
        uint256 _startX, 
        uint256 _startY, 
        uint256 _endX, 
        uint256 _endY, 
        uint256 _directionX, 
        uint256 _directionY
    ) internal pure returns (bool) {
        if (_foundPath) {
            return true;
        }
        uint256 curX = _startX;
        uint256 curY = _startY;
        uint256 curCost = _field[_startX][_startY];


        while (true) {
            curX += _directionX;
            curY += _directionY;
            ++curCost;

            if (_field[curX][curY] == 0) {
                _field[curX][curY] = curCost;
                _source[curX][curY] = composeData(_startX, _startY);
            } else if ((curX == _endX) && (curY == _endY)) {
                _field[curX][curY] = curCost;
                _source[curX][curY] = composeData(_startX, _startY);
                return true;
            } else {
                return _foundPath;
            }

            uint256 priority = _field[curX][curY] + distance(curX, curY, _endX, _endY);
            // check neighbouring cells, i.e. check if cur_x, cur_y is a jump point.
            if (_directionX == 0) {
                if ((_field[curX+1][curY] == 1024) && (_field[curX+1][curY+_directionY] < 1024)) {
                    queueJumptPoint(_pq, curX, curY, priority);
                    return _foundPath;
                }
                if ((_field[curX-1][curY] == 1024) && (_field[curX-1][curY+_directionY] < 1024)) {
                    queueJumptPoint(_pq, curX, curY, priority);
                    return _foundPath;
                }
            } else if (_directionY == 0) {
                if ((_field[curX][curY+1] == 1024) && (_field[curX+_directionX][curY+1] < 1024)) {
                    queueJumptPoint(_pq, curX, curY, priority);
                    return _foundPath;
                }
                if ((_field[curX][curY-1] == 1024) && (_field[curX+_directionX][curY-1] < 1024)) {
                    queueJumptPoint(_pq, curX, curY, priority);
                    return _foundPath;
                }
            }

        }
    }
}
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/*
 * Coordinate supplies some basic function for coordinate opperation.
 * Only use this lib for coordinate of which x and y are smaller than 256.
 * Modify {compose, decompose} functions in order to extend this lib to large field.
 */
library Coordinate {
    /*
     * @note return max(abs(x1-x2), abs(y1-y2))
     */
    function distance(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2) internal pure returns (uint256) {
        uint256 distX = _x1 < _x2 ? _x2 - _x1 : _x1 - _x2;
        uint256 distY = _y1 < _y2 ? _y2 - _y1 : _y1 - _y2;
        return distX < distY ? distY : distX;
    }

    function distance(uint256 _from, uint256 _to) internal pure returns (uint256) {
        (uint256 x1, uint256 y1) = decompose(_from);
        (uint256 x2, uint256 y2) = decompose(_to);
        return distance(x1, y1, x2, y2);
    }

    /*
     * @note compose coordinate x and y to a single value
     */
    function compose(uint256 _x, uint256 _y) internal pure returns (uint256) {
        return (_x << 8) + _y;
    }

    /*
     * @note decompose a single value to coordinate x and y
     */
    function decompose(uint256 _data) internal pure returns (uint256, uint256) {
        return (_data / 256, _data % 256);
    }
}
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @dev e.g. [1, 2, 3, 0, 0, 0]   head = 0,  tail = 3
 */
struct Queue {
  uint256 head; // included
  uint256 tail; // excluded
  uint256[] data;
}

using Q for Queue global;

library Q {
  function New(uint256 _length) internal pure returns (Queue memory) {
    return Queue({ head: 0, tail: 0, data: new uint256[](_length) });
  }

  function IsEmpty(Queue memory _q) internal pure returns (bool) {
    return _q.head == _q.tail;
  }

  function IsFull(Queue memory _q) internal pure returns (bool) {
    return ((_q.tail + 1) % _q.data.length) == _q.head;
  }

  function AddElement(
    Queue memory _q,
    uint256 _data
  ) internal pure {
    // require(!_q.IsFull(), "Q is full");
    if (_q.IsFull()) {
        return;
    }
    _q.data[_q.tail] = _data;
    _q.tail = (_q.tail + 1) % _q.data.length;
  }

  function PopElement(Queue memory _q) internal pure returns (uint256 data) {
    if (_q.IsEmpty()) {
      return 0;
    }
    data = _q.data[_q.head];
    _q.head = (_q.head + 1) % _q.data.length;
  }

  function Clear(Queue memory _q) internal pure {
    _q.head = 0;
    _q.tail = 0;
  }
}

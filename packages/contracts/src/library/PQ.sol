// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct PriorityQueue {
    uint256 num;
    uint256[] data;
    uint256[] priority;
}

using {IsEmpty, AddTask, PopTask} for PriorityQueue global;

function IsEmpty(PriorityQueue memory _pq) pure returns (bool) {
    return _pq.num == 0;
}

function AddTask(PriorityQueue memory _pq, uint256 _data, uint256 _priority) pure {
    uint256[] memory data = _pq.data;
    uint256[] memory priority = _pq.priority;
    uint i = _pq.num;
    require(i <= priority.length, "PQ is full");
    while ((i > 0) && (priority[i-1] < _priority)) {
        priority[i] = priority[i-1];
        data[i] = data[i-1];
        --i;
    }
    priority[i] = _priority;
    data[i] = _data;
    ++_pq.num;
    _pq.data = data;
    _pq.priority = priority;
}

function PopTask(PriorityQueue memory _pq) pure returns (uint256) {
    return _pq.data[--_pq.num];
}

library PQ {
    function New(uint256 _length) internal pure returns (PriorityQueue memory) {
        return PriorityQueue({num: 0, data: new uint256[](_length), priority: new uint256[](_length)});
    }
}
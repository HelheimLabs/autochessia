// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

uint8 constant PIECE_MAX_EFFECT_NUM = 8;

uint16 constant EFFECT_WITH_MODIFIER_MASK = 0x8000; // 1000 0000 0000 0000
uint16 constant EFFECT_EVENT_TYPE_MASK = 0x7800; // 0111 1000 0000 0000
uint16 constant EFFECT_IS_DIRECT_MASK = 0x0400; // 0000 0100 0000 0000
uint24 constant MODIFICATION_MASK = 0x0fffff; // 0000 1111 1111 1111 1111 1111
uint16 constant CHANGE_OPPERATION_MASK = 0x8000; // 1000 0000 0000 0000
uint16 constant CHANGE_SIGN_MASK = 0x4000; // 0100 0000 0000 0000

uint8 constant EFFECT_NUM_IN_TRIGGER = 2;
uint96 constant TRIGGER_SUB_ACTION_SELECTOR_MASK = 0x800000000000000000;
uint96 constant TRIGGER_DATA_MASK = 0xffffffffffffffff;

/*
 * status (uint16) doc
 * 1st bit: FORBIDEN
 * 2nd bit: FORBIDEN
 * 3rd bit: can act
 * 4th bit: can move
 * 5th bit: can attack
 * 6th bit: can cast spells
 */
uint16 constant CAN_ACT = 0x2000; // 0010 0000 0000 0000
uint16 constant CAN_MOVE = 0x1000; // 0001 0000 0000 0000
uint16 constant CAN_ATTACK = 0x0800; // 0000 1000 0000 0000
uint16 constant CAN_CAST = 0x0400; // 0000 0100 0000 0000

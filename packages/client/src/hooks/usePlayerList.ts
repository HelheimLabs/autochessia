import { useEffect, useState, useMemo } from 'react';
import { useComponentValue, useRows, useRow } from "@latticexyz/react";
import { useMUD } from "../MUDContext";
import { generateAvatar, shortenAddress } from '../lib/ulits'


const usePlayerList = () => {

  const {
    components: { Board, Player, PlayerGlobal },
    systemCalls: { placeToBoard, changeHeroCoordinate },
    network: { localAccount, playerEntity, storeCache, },
  } = useMUD();


  const _playerList = useRows(storeCache, { table: "Player" })

  const playerListData = useMemo(() => {

    return _playerList.map(item => ({
      id: item.key.addr,
      name: shortenAddress(item.key.addr),
      avatar: generateAvatar(item.key.addr),
      level: item.value.tier + 1,
      hp: item.value.health,
      maxHp: 30,
      coin: item.value.coin
    }))

  }, [_playerList])
  console.log({ playerListData })


  return {
    playerListData,
    localAccount
  };
}

export default usePlayerList;
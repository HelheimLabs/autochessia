import { useMUD } from "@/MUDContext";
import { useComponentValue } from "@latticexyz/react";
import { useCallback } from "react";

export function useAutoBattleFn() {
  const {
    components: { PlayerGlobal },
    systemCalls: { autoBattle },
    network: { localAccount, playerEntity },
  } = useMUD();

  const _playerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const autoBattleFn = useCallback(async () => {
    if (!_playerGlobal) {
      console.log("unknown player");
      return false;
    }
    await autoBattle(_playerGlobal.gameId, localAccount);
    return true;
  }, [_playerGlobal, autoBattle, localAccount]);

  return { autoBattleFn };
}

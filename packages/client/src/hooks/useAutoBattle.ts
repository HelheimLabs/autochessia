import dayjs from "dayjs";
import { useEffect, useRef, useState } from "react";
import { useAutoBattleFn } from "./useAutoBattleFn";

export function useAutoBattle() {
  const { autoBattleFn } = useAutoBattleFn();
  const [shouldRun, setShouldRun] = useState<boolean>(false);
  const tick = useRef(shouldRun);

  tick.current = shouldRun;

  const runAutoBattle = () => {
    if (tick.current) {
      setTimeout(() => {
        autoBattleFn()
          .then(() => {
            console.log("auto run");
            runAutoBattle();
          })
          .catch((e) => {
            console.error(e);
          });
      }, 500);
    }
  };

  useEffect(() => {
    if (shouldRun) {
      console.log("run");

      runAutoBattle();
    }
  }, [shouldRun]);

  return { setShouldRun, shouldRun };
}

import dayjs from "dayjs";
import { useEffect, useState } from "react";
import { useAutoBattleFn } from "./useAutoBattleFn";

export function useAutoBattle() {
  const { autoBattleFn } = useAutoBattleFn();
  const [shouldRun, setShouldRun] = useState<boolean>(false);
  const [isRunning, setIsRunning] = useState<boolean>(false);
  const [runningStart, setRunningStart] = useState<number>(0);

  useEffect(() => {
    if (shouldRun) {
      if (!isRunning) {
        // set to now
        setRunningStart(dayjs().unix());
        setIsRunning(true);

        // delay 0.5s to avoid on-chain fail and minimal tick interval
        setTimeout(() => {
          // run auto battle
          autoBattleFn()
            .then(() => {
              setIsRunning(false);
            })
            .catch((e) => {
              setIsRunning(false);
              console.error(e);
            });
        }, 500);
      }
    }
  }, [shouldRun, isRunning, setIsRunning, autoBattleFn, setRunningStart]);

  // check timeout
  useEffect(() => {
    if (shouldRun) {
      const interval = setInterval(() => {
        // running timeout 10s
        if (dayjs().unix() - runningStart > 10) {
          setIsRunning(false);
          console.log("running tick timeout");
        }
        // check every seconds:
      }, 1000);
      return () => {
        clearInterval(interval);
      };
    }
  }, [runningStart, shouldRun]);

  return { setShouldRun, shouldRun, isRunning };
}

import dayjs from "dayjs";
import { useEffect, useState } from "react";
import useChessboard from "./useChessboard";

export function useAutoBattle() {
  const { autoBattleFn } = useChessboard();
  const [shouldRun, setShouldRun] = useState<boolean>(false);
  const [isRunning, setIsRunning] = useState<boolean>(false);
  const [runningStart, setRunningStart] = useState<number>(0);

  useEffect(() => {
    if (shouldRun) {
      const interval = setInterval(() => {
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
      }, 100);

      return () => {
        clearInterval(interval);
      };
    }
  }, [
    shouldRun,
    isRunning,
    setIsRunning,
    autoBattleFn,
    setRunningStart,
    runningStart,
  ]);

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

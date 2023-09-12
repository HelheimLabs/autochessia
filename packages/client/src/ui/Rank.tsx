import React, { useState } from "react";

import { useMUD } from "../MUDContext";
import { useComponentValue, useEntityQuery } from "@latticexyz/react";
import { Has, getComponentValue } from "@latticexyz/recs";
import { shortenAddress } from "@/lib/utils";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";
dayjs.extend(relativeTime);

const Leaderboard = () => {
  const {
    components: { Rank },
    network: { localAccount, playerEntity },
  } = useMUD();

  const rankList = useEntityQuery([Has(Rank)])
    .map((row) => ({
      ...getComponentValue(Rank, row),
      addr: row,
    }))
    ?.sort((a, b) => ((b.score as number) - a.score) as number);

  const [open, setOpen] = useState(false);

  return (
    <div
      className={`notice-board   w-[250px]  overflow-auto bg-blue-500 p-2 rounded-lg shadow  ${
        open ? "h-[300px]" : "h-[50px]"
      }`}
    >
      <h2
        className="text-xl user-select-none cursor-pointer  font-bold mb-4  text-gray-50 text-center "
        onClick={() => setOpen((prev) => !prev)}
      >
        Leaderboard
      </h2>

      <div className="space-y-2">
        {rankList?.map((user) => (
          <div key={user.addr} className="flex items-center">
            <span className="text-sm font-medium text-gray-800">
              {shortenAddress(user.addr)}
            </span>
            <span className="text-sm font-medium text-gray-600 ml-[10px]">
              {user.score}
            </span>

            <span className="ml-[10px] text-sm text-red-200">
              {dayjs(Number(user.createdAtBlock) * 1000).fromNow()}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Leaderboard;

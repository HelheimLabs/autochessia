import React from "react";

import { useMUD } from "../MUDContext";
import { useComponentValue, useEntityQuery } from "@latticexyz/react";
import { Has, getComponentValue } from "@latticexyz/recs";
import { shortenAddress } from "@/lib/utils";

const Leaderboard = () => {
  const {
    components: { Rank },
    network: { localAccount, playerEntity },
  } = useMUD();

  const rankList = useEntityQuery([Has(Rank)]).map((row) => ({
    ...getComponentValue(Rank, row),
    addr: row,
  }));

  console.log(rankList);

  return (
    <div className="notice-board w-[auto] h-[300px] overflow-auto bg-blue-500 p-2 rounded-lg shadow fixed right-3 top-40">
      <h2 className="text-2xl font-bold mb-4  text-gray-50">Leaderboard</h2>

      <div className="space-y-2">
        {rankList?.map((user) => (
          <div key={user.addr} className="flex items-center">
            <span className="text-sm font-medium text-gray-800">
              {shortenAddress(user.addr)}
            </span>

            <span className="ml-auto text-sm text-gray-600">
              {user.createdAtBlock}
            </span>

            <span className="text-sm font-medium text-gray-600 ml-4">
              {user.score}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Leaderboard;

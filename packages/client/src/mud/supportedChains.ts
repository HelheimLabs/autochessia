/*
 * The supported chains.
 * By default, there are only two chains here:
 *
 * - mudFoundry, the chain running on anvil that pnpm dev
 *   starts by default. It is similar to the viem anvil chain
 *   (see https://viem.sh/docs/clients/test.html), but with the
 *   basefee set to zero to avoid transaction fees.
 * - latticeTestnet, our public test network.
 *

 */

import {
  MUDChain,
  latticeTestnet,
  mudFoundry,
} from "@latticexyz/common/chains";

/*
 * See https://mud.dev/tutorials/minimal/deploy#run-the-user-interface
 * for instructions on how to add networks.
 */
export const altLayerTestnet = {
  name: "AltLayer Testnet",
  id: 1398383,
  network: "altLayer-testnet",
  nativeCurrency: { decimals: 18, name: "Ether", symbol: "ETH" },
  rpcUrls: {
    default: {
      http: ["https://flashlayer.alt.technology/autochessia37806fd60"],
      webSocket: ["wss://flashlayer.alt.technology/autochessia37806fd60"],
    },
    public: {
      http: ["https://flashlayer.alt.technology/autochessia37806fd60"],
      webSocket: ["wss://flashlayer.alt.technology/autochessia37806fd60"],
    },
  },
  blockExplorers: {
    default: {
      name: "altLayerScan",
      url: "https://explorer.alt.technology?rpcUrl=https://flashlayer.alt.technology/autochessia37806fd60",
    },
  },
  fees: {
    defaultPriorityFee: BigInt(0),
  },
} as const satisfies MUDChain;

// If you are deploying to chains other than anvil or Lattice testnet, add them here
export const supportedChains: (MUDChain & { indexerUrl?: string })[] = [
  {
    ...altLayerTestnet,
    indexerUrl: "https://altlayer-testnet-indexer.fly.dev/trpc",
  },
  {
    ...latticeTestnet,
    indexerUrl: "https://lattice-testnet-indexer.fly.dev/trpc",
  },
  mudFoundry,
];

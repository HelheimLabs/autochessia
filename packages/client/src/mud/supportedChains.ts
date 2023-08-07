import { MUDChain, latticeTestnet } from "@latticexyz/common/chains";
import { arbitrumGoerli, foundry } from "@wagmi/chains";

export const altLayerTestnet = {
  name: "AltLayer Testnet",
  id: 1129710,
  network: "altLayer-testnet",
  nativeCurrency: { decimals: 18, name: "Ether", symbol: "ETH" },
  rpcUrls: {
    default: {
      http: ["https://flashlayer.alt.technology/autochessia7806fd60"],
      webSocket: ["wss://flashlayer.alt.technology/autochessia7806fd60"],
    },
    public: {
      http: ["https://flashlayer.alt.technology/autochessia7806fd60"],
      webSocket: ["wss://flashlayer.alt.technology/autochessia7806fd60"],
    },
  },
  blockExplorers: {
    default: {
      name: "altLayerScan",
      url: "https://explorer.alt.technology?rpcUrl=https://flashlayer.alt.technology/autochessia7806fd60",
    },
  },
  testnet: true,
};

// If you are deploying to chains other than anvil or Lattice testnet, add them here
export const supportedChains: MUDChain[] = [
  foundry,
  latticeTestnet,
  altLayerTestnet,
];

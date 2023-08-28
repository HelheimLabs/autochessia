import { getBurnerPrivateKey } from "@latticexyz/common";
import worldsJson from "contracts/worlds.json";
import { supportedChains } from "./supportedChains";
import { latticeTestnet } from "@latticexyz/common/chains";

const worlds = worldsJson as Partial<
  Record<string, { address: string; blockNumber?: number }>
>;

export async function getNetworkConfig() {
  const params = new URLSearchParams(window.location.search);
  const chainId = Number(params.get("chainId") || latticeTestnet.id);
  const chainIndex = supportedChains.findIndex((c) => c.id === chainId);
  const chain = supportedChains[chainIndex];
  if (!chain) {
    throw new Error(`Chain ${chainId} not found`);
  }

  const indexerUrl = chain.indexerUrl;

  const world = worlds[chain.id.toString()];
  const worldAddress = params.get("worldAddress") || world?.address;
  if (!worldAddress) {
    throw new Error(
      `No world address found for chain ${chainId}. Did you run \`mud deploy\`?`
    );
  }

  const initialBlockNumber = params.has("initialBlockNumber")
    ? Number(params.get("initialBlockNumber"))
    : world?.blockNumber ?? 0n;

  return {
    privateKey: getBurnerPrivateKey(),
    chainId,
    chain,
    faucetServiceUrl: params.get("faucet") ?? chain.faucetUrl,
    worldAddress,
    initialBlockNumber,
    indexerUrl,
  };
}

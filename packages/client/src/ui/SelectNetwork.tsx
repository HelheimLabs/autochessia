import { Select } from "antd";
import { supportedChains } from "../mud/supportedChains";
import { useMUD } from "../MUDContext";

export function SelectNetwork() {
  const mudCtx = useMUD();
  const chainId = mudCtx.network.publicClient.chain;
  const chainIndex = supportedChains.findIndex((c) => c.id === chainId.id);
  const chain = supportedChains[chainIndex];

  const onChange = (value: string) => {
    const searchParams = new URLSearchParams(window.location.search);
    searchParams.set("chainId", value);

    const newUrl = `${window.location.pathname}?${searchParams.toString()}`;
    window.history.replaceState(null, "", newUrl);
    window.location.reload();
  };

  return (
    <Select
      showSearch
      placeholder="Select Network"
      optionFilterProp="children"
      onChange={onChange}
      filterOption={(input, option) =>
        (option?.label ?? "").toLowerCase().includes(input.toLowerCase())
      }
      options={supportedChains.map((c) => {
        return { label: c.name, value: c.id };
      })}
      defaultValue={chain?.name}
    />
  );
}

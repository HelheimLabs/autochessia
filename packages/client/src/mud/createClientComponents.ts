import { SetupNetworkResult } from "./setupNetwork";
import { overridableComponent } from "@latticexyz/recs";

export type ClientComponents = ReturnType<typeof createClientComponents>;

export function createClientComponents({ components }: SetupNetworkResult) {
  return {
    ...components,
    Board: overridableComponent(components.Board),
    Player: overridableComponent(components.Player),
    Hero: overridableComponent(components.Hero),
    // add your client components or overrides here
  };
}

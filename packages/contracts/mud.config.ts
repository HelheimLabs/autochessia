import { mudConfig } from "@latticexyz/world/register";

export default mudConfig({
  // namespace: "AutoChess",
  systems: {
    AutoBattleSystem: {
      name: "autoBattle",
      openAccess: true,
    }
  },
  tables: {
    GameConfig: {
      keySchema: {},
      schema: {
        length: "uint256",
        width: "uint256"
      }
    },
    Creatures: {
      schema: {
        health: "uint256",
        attack: "uint256",
        range: "uint256",
        defense: "uint256",
        speed: "uint256"
      }
    },
    Counter: {
      keySchema: {},
      schema: "uint32",
    },
  },
});

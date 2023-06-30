import { mudConfig } from "@latticexyz/world/register";

export default mudConfig({
  // namespace: "AutoChess",
  systems: {
    AutoBattleSystem: {
      name: "autoBattle",
      openAccess: true,
    }
  },
  enums: {
    BoardStatus: ["UNINITIATED", "PREPARING", "INBATTLE"],
  },
  tables: {
    GameConfig: {
      keySchema: {},
      schema: {
        boardIndex: "uint32",
        creatureIndex: "uint32",
        length: "uint32",
        width: "uint32",
      }
    },
    Player: {
      schema: {
        inBoard: "bytes32",
      }
    },
    Creatures: {
      schema: {
        health: "uint32",
        attack: "uint32",
        range: "uint32",
        defense: "uint32",
        speed: "uint32",
      }
    },
    Piece: {
      schema: {
        creature: "bytes32",
        owner: "uint8", // 0: neutral, 1: player1, 2:player2
        curHealth: "uint32",
        x: "uint32",
        y: "uint32",
      }
    },
    Board: {
      schema: {
        pieces: "bytes32[]",
        player1: "address",
        player2: "address",
        status: "BoardStatus",
        round: "uint32",
        turn: "uint32",
        lastWinner: "uint8",
      }
    },
    Counter: {
      keySchema: {},
      schema: "uint32",
    },
  },
});

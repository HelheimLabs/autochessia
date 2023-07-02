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
        revenue: "uint8",
        rvnGrowthPeriod: "uint8",
        storeSlotNum: "uint8",
      }
    },
    ShopConfig: {
      keySchema: {},
      schema: {
        slotNum: "uint8",
        refreshPrice: "uint8",
        expPrice: "uint8",
        tierPrice: "uint8[]",
        tierRate: "uint8[]",
      }
    },
    Player: {
      schema: {
        status: "PlayerStatus",
        coin: "uint32",
        tier: "uint8",
        pieces: "bytes32[]",
        shop: "uint64[]", // creature id + tier
        store: "uint64[]",
      }
    },
    CreatureConfig: {
      keySchema: {},
      schema: {
        healthAmplifier: "uint8[]",   // decimal 2   // exmaple: [210,330]
        attackAmplifier: "uint8[]",   // decimal 2
        defenseAmplifier: "uint8[]",   // decimal 2
      }
    },
    Creatures: {
      schema: {
        health: "uint32",
        attack: "uint32",
        range: "uint32",
        defense: "uint32",
        speed: "uint32",
        movement: "uint32",
        uri: "string",
      }
    },
    Piece: {
      schema: {
        creature: "bytes32",
        tier: "uint8",
        x: "uint32", // initial x
        y: "uint32", // initial y
      }
    },
    PieceInBattle: {
      schema: {
        pieceId: "bytes32",
        curHealth: "uint32",
        x: "uint32",
        y: "uint32",
      }
    },
    Game: {
      schema: {
        player1: "address",
        player2: "address",
        status: "GameStatus",
        round: "uint32",
      }
    },
    // key: bytes32(address)
    Board: {
      schema: {
        enemy: "address",
        status: "BoardStatus",
        turn: "uint32",
        // pieces in battle
        pieces: "bytes32[]",
        enemyPieces: "bytes32[]",
      }
    },
    Counter: {
      keySchema: {},
      schema: "uint32",
    },
  },
});

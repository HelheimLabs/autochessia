import { mudConfig } from "@latticexyz/world/register";

export default mudConfig({
  // namespace: "AutoChess",
  systems: {
    AutoBattleSystem: {
      name: "autoBattle",
      openAccess: true,
    },
    // sub-system
    CoinIncomeSystem: {
      name: "coinIncome",
      openAccess: false,
      // add some system here
      accessList: [],
    },
    RefreshHerosSystem: {
      name: "refreshHeros",
      openAccess: false,
      // add some system here
      accessList: [],
    },
  },
  enums: {
    PlayerStatus: ["UNINITIATED", "INGAME"],
    GameStatus: ["UNINITIATED", "PREPARING", "INBATTLE", "FINISHED"],
    BoardStatus: ["UNINITIATED", "INBATTLE", "FINISHED"],
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
        inventorySlotNum: "uint8",
      },
    },
    ShopConfig: {
      keySchema: {},
      schema: {
        slotNum: "uint8",
        refreshPrice: "uint8",
        expPrice: "uint8",
        tierPrice: "uint8[]",
        tierRate: "uint8[]",
      },
    },
    Player: {
      keySchema: {
        addr: "address",
      },
      schema: {
        gameId: "bytes32",
        status: "PlayerStatus",
        health: "uint8",
        record: "int8",
        coin: "uint32",
        tier: "uint8",
        pieces: "bytes32[]",
        heroAltar: "uint64[]", // list user can buy, creature id + tier
        inventory: "uint64[]",
      },
    },
    CreatureConfig: {
      keySchema: {},
      schema: {
        healthAmplifier: "uint8[]", // decimal 2   // exmaple: [210,330]
        attackAmplifier: "uint8[]", // decimal 2
        defenseAmplifier: "uint8[]", // decimal 2
      },
    },
    Creatures: {
      keySchema: {
        index: "uint32",
      },
      schema: {
        health: "uint32",
        attack: "uint32",
        range: "uint32",
        defense: "uint32",
        speed: "uint32",
        movement: "uint32",
        uri: "string",
      },
    },
    Piece: {
      schema: {
        creature: "uint32",
        tier: "uint8",
        x: "uint32", // initial x
        y: "uint32", // initial y
      },
    },
    PieceInBattle: {
      schema: {
        pieceId: "bytes32",
        curHealth: "uint32",
        x: "uint32",
        y: "uint32",
      },
    },
    Game: {
      keySchema: {
        index: "uint32",
      },
      schema: {
        player1: "address",
        player2: "address",
        status: "GameStatus",
        round: "uint32",
        finishedBoard: "uint8",
        winner: "uint8",
      }
    },
    Board: {
      keySchema: {
        addr: "address",
      },
      schema: {
        enemy: "address",
        status: "BoardStatus",
        turn: "uint32",
        // pieces in battle
        pieces: "bytes32[]",
        enemyPieces: "bytes32[]",
      },
    },
    Counter: {
      keySchema: {},
      schema: "uint32",
    },
  },
});

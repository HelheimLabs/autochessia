import { mudConfig } from "@latticexyz/world/register";

export default mudConfig({
  // namespace: "AutoChess",
  systems: {
    AutoBattleSystem: {
      name: "autoBattle",
      openAccess: true,
    },
    MatchingSystem: {
      name: "matching",
      openAccess: true,
    },
    // public JPS lib system
    JPSLibSystem: {
      name: "jpsLib",
      openAccess: true,
    },
    ShopSystem: {
      name: "shopSystem",
      openAccess: true,
    },
    EncodeSystem: {
      name: "encode",
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
    ExperienceSystem: {
      name: "experience",
      openAccess: false,
      // add some system here
      accessList: [],
    },
    RoundSettlementSystem: {
      name: "roundSettlement",
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
        gameIndex: "uint32",
        creatureIndex: "uint32",
        length: "uint32",
        width: "uint32",
        roundInterval: "uint32",  // num of blocks
        revenue: "uint8",
        rvnGrowthPeriod: "uint8",
        inventorySlotNum: "uint8",
        expUpgrade: "uint8[]", // example: [1,1,4,8,16]
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
        roomId: "bytes32",
        gameId: "uint32",
        status: "PlayerStatus",
        health: "uint8",
        streakCount: "int8",
        coin: "uint32",
        tier: "uint8", // start from 0
        exp: "uint32", // experience
        pieces: "bytes32[]",
        heroAltar: "uint64[]", // list heros that user can buy, creature id + tier
        inventory: "uint64[]",
      },
    },
    CreatureConfig: {
      keySchema: {},
      schema: {
        healthAmplifier: "uint16[]", // decimal 2   // exmaple: [210,330]
        attackAmplifier: "uint16[]", // decimal 2
        defenseAmplifier: "uint16[]", // decimal 2
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
    WaitingRoom: {
      schema: {
        player1: "address",
        player2: "address",
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
        startFrom: "uint64", // block num
        finishedBoard: "uint8",
        winner: "uint8",
      },
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
  modules: [
    {
      name: "UniqueEntityModule",
      root: true,
      args: [],
    },
  ],
});

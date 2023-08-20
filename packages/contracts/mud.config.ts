import { mudConfig } from "@latticexyz/world/register";
import "@latticexyz/world/snapsync";

export default mudConfig({
  snapSync: true,
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
    RefreshHeroesSystem: {
      name: "refreshHeroes",
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
    MergeSystem: {
      name: "merge",
      openAccess: false,
      // add some system here
      accessList: [],
    },
    PieceDecisionMakeSystem: {
      name: "decisionMake",
      openAccess: false,
      // add some system here
      accessList: [],
    },
    PieceInitializerSystem: {
      name: "initPiece",
      openAccess: false,
      // add some system here
      accessList: [],
    },
    PasswordProofVerifySystem: {
      name: "pwProofVerify",
      openAccess: true,
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
    NetworkConfig: {
      keySchema: {
        chainId: "uint256",
      },
      schema: {
        vrfCoordinator: "address", // set real coordinator or mock one
        vrfSubId: "uint64",
        vrfKeyHash: "bytes32",
        vrfMinimumRequestConfirmations: "uint16",
        vrfCallbackGasLimit: "uint32",
        vrfNumWords: "uint32",
      },
    },
    GameConfig: {
      keySchema: {
        index: "uint32",
      },
      schema: {
        gameIndex: "uint32",
        creatureIndex: "uint32",
        length: "uint32",
        width: "uint32",
        roundInterval: "uint32", // num of blocks
        revenue: "uint8",
        rvnGrowthPeriod: "uint8",
        inventorySlotNum: "uint8",
        expUpgrade: "uint8[]", // example: [1,1,4,8,16]
      },
    },
    ShopConfig: {
      keySchema: {
        index: "uint8",
      },
      schema: {
        slotNum: "uint8",
        refreshPrice: "uint8",
        expPrice: "uint8",
        tierPrice: "uint8[]",
        tierRate: "uint8[]",
      },
    },
    VrfRequest: {
      keySchema: {
        requestId: "uint256",
      },
      schema: {
        gameId: "uint32",
        fulfilled: "bool",
      },
    },
    PlayerGlobal: {
      keySchema: {
        addr: "address",
      },
      schema: {
        roomId: "bytes32",
        gameId: "uint32",
        status: "PlayerStatus",
      },
    },
    Player: {
      keySchema: {
        addr: "address",
      },
      schema: {
        health: "uint8",
        streakCount: "int8",
        coin: "uint32",
        tier: "uint8", // start from 0
        exp: "uint32", // experience
        heroes: "bytes32[]",
        heroAltar: "uint64[]", // list heros that user can buy, creature id + tier
        inventory: "uint64[]",
      },
    },
    CreatureConfig: {
      keySchema: {
        index: "uint32",
      },
      schema: {
        healthAmplifier: "uint16[]", // decimal 2   // example: [210,330]
        attackAmplifier: "uint16[]", // decimal 2
        defenseAmplifier: "uint16[]", // decimal 2
      },
    },
    Creature: {
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
    Hero: {
      schema: {
        creatureId: "uint32",
        tier: "uint8",
        x: "uint32",
        y: "uint32",
      },
    },
    Piece: {
      // using uint8 in order to put all data into one slot of bytes32
      // 8+8+8+32+32+8+32+32+8+32+32=232 < 256
      schema: {
        x: "uint8",
        y: "uint8",
        tier: "uint8",
        health: "uint32",
        attack: "uint32",
        range: "uint8",
        defense: "uint32",
        speed: "uint32",
        movement: "uint8",
        maxHealth: "uint32",
        creatureId: "uint32",
      },
    },
    WaitingRoom: {
      schema: {
        seatNum: "uint8",
        withPassword: "bool",
        createdAtBlock: "uint64",
        updatedAtBlock: "uint64",
        players: "address[]",
      },
    },
    WaitingRoomPassword: {
      schema: {
        passwordHash: "bytes32",
      },
    },
    GameRecord: {
      keySchema: {
        index: "uint32",
      },
      schema: {
        players: "address[]",
      },
    },
    Game: {
      keySchema: {
        index: "uint32",
      },
      schema: {
        status: "GameStatus",
        round: "uint32",
        startFrom: "uint32", // current round start block timestamp
        finishedBoard: "uint8",
        globalRandomNumber: "uint256",
        players: "address[]",
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
    ZkVerifier: {
      keySchema: {},
      schema: {
        password: "address",
      },
    },
  },
  modules: [
    {
      name: "UniqueEntityModule",
      root: true,
      args: [],
    },
    // { name: "SnapSyncModule", root: true, args: [] },
  ],
});

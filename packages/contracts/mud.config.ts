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
    ShopSystem: {
      name: "shopSystem",
      openAccess: true,
    },
    PasswordProofVerifySystem: {
      name: "pwProofVerify",
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
      accessList: [],
    },
    PveBotSystem: {
      name: "PveBotSystem",
      openAccess: false,
      accessList: [],
    },
    ExperienceSystem: {
      name: "experience",
      openAccess: false,
      accessList: [],
    },
    RoundSettlementSystem: {
      name: "roundSettlement",
      openAccess: false,
      accessList: [],
    },
    MergeSystem: {
      name: "merge",
      openAccess: false,
      accessList: [],
    },
    PieceDecisionMakeSystem: {
      name: "decisionMake",
      openAccess: false,
      accessList: [],
    },
    PieceInitializerSystem: {
      name: "initPiece",
      openAccess: false,
      accessList: [],
    },
    PieceActionSimulatorSystem: {
      name: "actionSimulator",
      openAccess: false,
      accessList: [],
    },
  },
  enums: {
    PlayerStatus: ["UNINITIATED", "INGAME"],
    GameStatus: ["UNINITIATED", "PREPARING", "INBATTLE", "FINISHED"],
    BoardStatus: ["UNINITIATED", "INBATTLE", "FINISHED"],
    EventType: ["NONE", "ON_START", "ON_MOVE", "ON_ATTACK", "ON_CAST", "ON_DAMAGE", "ON_DEATH", "ON_END"],
    Attribute: [
      "NONE",
      "STATUS",
      "HEALTH",
      "MAX_HEALTH",
      "ATTACK",
      "RANGE",
      "DEFENSE",
      "SPEED",
      "MOVEMENT",
      "CRIT",
      "DMG_REDUCTION",
      "EVASION",
      "IMMUNITY",
    ],
    CreatureRace: ["UNKNOWN", "TROLL", "PANDAREN", "ORC", "HUMAN", "GOD"],
    CreatureClass: ["UNKNOWN", "KNIGHT", "WARLOCK", "ASSASSIN", "WARRIOR", "MAGE"],
    EnvExtractor: ["POSSIBILITY", "ALLY_AROUND_NUMBER"],
    ApplyTo: ["SELF", "DIRECT", "INDIRECT"],
    DamageType: ["REAL", "PHYSICAL", "MAGICAL"],
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
        // creatureCounter is concatenated by 5 uint8 of which each represents the creature number of the same rarity
        // higher bit the uint8 locates at, higher rarity the number represents.
        creatureCounter: "uint40",
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
        // price = rarity
        // rarityPrice: "uint8[]",
        rarityRate: "uint40[]",
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
        locked: "bool", // whether the heroes in altar are locked
        heroOrderIdx: "uint32", // auto increment idx, refresh on every game start
        heroes: "bytes32[]",
        heroAltar: "uint24[]", // list heros that user can buy, creature id + tier
        inventory: "uint24[]",
      },
    },
    Creature: {
      keySchema: {
        // uint16 index = | uint8 tier | uint8 rarity | uint8 internal_index |
        index: "uint24",
      },
      schema: {
        race: "CreatureRace",
        class: "CreatureClass",
        health: "uint32",
        attack: "uint32",
        range: "uint32",
        defense: "uint32",
        speed: "uint32",
        movement: "uint32",
      },
    },
    CreatureUri: {
      keySchema: {
        index: "uint16", // creature index
      },
      schema: {
        uri: "string",
      },
    },
    Hero: {
      schema: {
        creatureId: "uint24",
        x: "uint32",
        y: "uint32",
      },
    },
    Piece: {
      // put all data into one slot of bytes32
      // 8+8+32+16+192=256
      schema: {
        x: "uint8",
        y: "uint8",
        // temporarily lessen health in order to limit table value's length
        // todo change health back to uint32
        health: "uint24",
        creatureId: "uint24",
        effects: "uint192",
      },
    },
    Effect: {
      keySchema: {
        index: "uint16",
      },
      schema: {
        modification: "uint160",
        trigger: "uint96",
      },
    },
    RaceSynergyEffect: {
      keySchema: {
        count: "uint256",
      },
      schema: {
        applyTo: "uint8",
        effect: "uint24",
      },
    },
    ClassSynergyEffect: {
      keySchema: {
        count: "uint256",
      },
      schema: {
        applyTo: "uint8",
        effect: "uint24",
      },
    },
    WaitingRoom: {
      schema: {
        seatNum: "uint8",
        withPassword: "bool",
        createdAtBlock: "uint32",
        updatedAtBlock: "uint32",
        players: "address[]",
      },
    },
    WaitingRoomPassword: {
      schema: {
        passwordHash: "bytes32",
      },
    },
    Rank: {
      keySchema: {
        addr: "address",
      },
      schema: {
        createdAtBlock: "uint32",
        score: "uint32",
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
        single: "bool",
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
  ],
});

import { mudConfig } from "@latticexyz/world/register";

export default mudConfig({
  enums: {
    PlayerStatus: ["UNINITIATED", "INGAME"],
    GameStatus: ["UNINITIATED", "PREPARING", "INBATTLE", "FINISHED"],
    BoardStatus: ["UNINITIATED", "INBATTLE", "FINISHED"],
    EventType: ["NONE", "ON_MOVE", "ON_ATTACK", "ON_CAST", "ON_DAMAGE", "ON_DEATH", "ON_END_TURN"],
    Attribute: ["NONE", "STATUS", "HEALTH", "MAX_HEALTH", "ATTACK", "RANGE", "DEFENSE", "SPEED", "MOVEMENT"],
    CreatureRace: ["UNKNOWN", "TROLL", "PANDAREN", "ORC", "HUMAN", "GOD"],
    CreatureClass: ["UNKNOWN", "KNIGHT", "WARLOCK", "ASSASSIN", "WARRIOR", "MAGE"],
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

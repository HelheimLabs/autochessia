// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {System} from "@latticexyz/world/src/System.sol";

import {IWorld} from "src/codegen/world/IWorld.sol";

import {IStore} from "@latticexyz/store/src/IStore.sol";

import {Game, NetworkConfig, NetworkConfigData, VrfRequest} from "src/codegen/index.sol";

import {VRFCoordinatorV2Interface} from "chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

interface VRFConsumerBaseV2Interface {
    error OnlyCoordinatorCanFulfill(address have, address want);

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}

contract RandomSystem is System, VRFConsumerBaseV2Interface {
    /**
     * not real random but it doesn't matter too much
     */
    function getRandomNumberInGame(uint32 gameId) public view returns (uint256) {
        uint256 r = Game.getGlobalRandomNumber(gameId);
        return uint256(keccak256(abi.encode(r, blockhash(block.number - 1), block.number, gasleft())));
    }

    function requestGlobalRandomNumber(uint32 gameId) public {
        NetworkConfigData memory networkConf = NetworkConfig.get(block.chainid);

        uint256 requestId = VRFCoordinatorV2Interface(networkConf.vrfCoordinator).requestRandomWords(
            networkConf.vrfKeyHash,
            networkConf.vrfSubId,
            networkConf.vrfMinimumRequestConfirmations,
            networkConf.vrfCallbackGasLimit,
            networkConf.vrfNumWords
        );

        // save requestId to gameId mapping
        VrfRequest.setGameId(requestId, gameId);
    }

    /**
     * @notice callback would directly call System contract, rather call world and world call system
     * @notice so you should pass world address as args
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual {
        require(!VrfRequest.getFulfilled(requestId), "request Id fulfilled");

        // get gameId
        uint32 gameId = VrfRequest.getGameId(requestId);

        // set random number to game
        Game.setGlobalRandomNumber(gameId, randomWords[0]);

        // set vrf request as fulfilled
        VrfRequest.setFulfilled(requestId, true);
    }

    /**
     * @notice callback would directly call System contract, rather call world and world call system
     * @notice so use msg.sender rather _msgSender()
     */
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        address vrfCoordinator = NetworkConfig.getVrfCoordinator(block.chainid);

        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

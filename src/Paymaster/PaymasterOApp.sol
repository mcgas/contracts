// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing LayerZero OApp protocol dependencies and Ownable
import {OApp, Origin, MessagingFee} from "../../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PaymasterOApp
 * @dev A LayerZero OApp-based contract that facilitates cross-chain messaging for the CustomPaymaster contract.
 *
 * This contract acts as an intermediary utility to enable CustomPaymaster to send and receive cross-chain messages, allowing
 * synchronization of subscription data across chains. Built on LayerZero's OApp protocol, it provides the necessary
 * functions to encode, send, and handle incoming messages, ensuring effective cross-chain communication.
 *
 * ## Role
 * - **Message Sending**: Encodes and sends messages from the source to a specified destination chain using LayerZero’s protocol.
 * - **Message Reception**: Receives and decodes messages originating from other chains to update local contract state.
 *
 * ## Relationship with Other Contracts
 * - **CustomPaymaster**: PaymasterOApp is utilized by the CustomPaymaster contract to streamline message handling and validation.
 * - **LayerZero OApp Protocol**: Interfaces directly with LayerZero’s OApp protocol for all cross-chain message management.
 *
 * ## State Variables
 * - **data**: Stores the most recent message received from the destination chain for demonstration purposes.
 *
 * @notice This contract serves as a utility for cross-chain messaging in the CustomPaymaster, leveraging LayerZero’s OApp protocol.
 */
contract PaymasterOApp is OApp, Ownable {
    /// Stores the most recent message received from a cross-chain communication.
    string public data;

    /**
     * @notice Initializes the contract with LayerZero endpoint and owner information.
     * @param _endpoint The LayerZero endpoint address to send and receive messages.
     * @param _owner The owner address for administrative control.
     */
    constructor(
        address _endpoint,
        address _owner
    ) OApp(_endpoint, _owner) Ownable(_owner) {}

    /**
     * @notice Sends a cross-chain message from the source to a specified destination chain.
     * @dev This function encodes the message and invokes LayerZero’s `_lzSend` method to relay it.
     *      Requires a specified amount of native gas for cross-chain message handling.
     * @param _dstEid The endpoint ID of the destination chain.
     * @param _message The message string to send to the destination chain.
     * @param _options Execution options, including gas settings for the destination chain.
     */
    function send(
        uint32 _dstEid,
        string memory _message,
        bytes calldata _options
    ) external payable {
        // Encode the message to bytes for cross-chain transmission
        bytes memory _payload = abi.encode(_message);

        _lzSend(
            _dstEid,
            _payload,
            _options,
            MessagingFee(msg.value, 0), // Fee in native gas; no ZRO tokens used here
            payable(msg.sender) // Refund address if message fails
        );
    }

    /**
     * @notice Internal function triggered upon message reception from another chain.
     * @dev This function decodes the incoming payload and updates the `data` variable.
     *      This function is called by the LayerZero protocol when a message is received.
     * @param _origin A struct containing origin chain details (e.g., chain ID).
     * @param _guid A unique identifier for the message packet.
     * @param payload Encoded message data received from the source chain.
     * @param executor The executor address specified by the OApp protocol (not used in this example).
     * @param options Additional options or data specified for the reception process.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address executor,
        bytes calldata options
    ) internal override {
        // Decode the payload; here, it is expected to be a string
        data = abi.decode(payload, (string));
    }
}

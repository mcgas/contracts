// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import "./SubscriptionManager.sol";
import "./PaymasterHelper.sol";

/**
 * @title CustomPaymaster
 * @dev Manages gas fee sponsorship by verifying the user’s subscription status and paying fees as required.
 *
 * This contract is designed to act as a paymaster, sponsoring gas fees for users with an active subscription.
 * It includes logic to:
 * - **Pre-Operation Validation**: Verifies that the user has an active subscription before the transaction is processed.
 * - **Gas Payment**: Pays the gas fee on behalf of the user if the subscription is valid.
 * - **Post-Operation Update**: Uses cross-chain messaging via the LayerZero OApp protocol to update the user's subscription status on other chains, if required.
 *
 * ## Purpose
 * The primary purpose of this contract is to provide a paymaster that covers gas fees for users who hold a valid subscription.
 * It acts as an intermediary that verifies the subscription before approving gas sponsorship and subsequently updates the subscription status as necessary.
 *
 * ## Contract Components
 * - **Pre-Operation Validation**: Validates that a user’s subscription is active through `SubscriptionManager`.
 * - **Gas Fee Payment**: Handles payment of gas fees in compliance with the UserOperation's requirements.
 * - **Cross-Chain Updates**: Uses LayerZero’s OApp protocol to update subscription status on other chains when cross-chain actions are involved.
 *
 * ## Relationship with Other Contracts
 * - **SubscriptionManager**: Checks subscription validity and status updates.
 * - **PaymasterHelper**: Provides auxiliary functions to handle complex paymaster logic.
 * - **LayerZero OApp Protocol**: Handles cross-chain messaging for updating the user’s subscription status on other chains.
 *
 * @notice This contract sponsors gas fees for users with active subscriptions and handles the necessary cross-chain updates.
 */
contract CustomPaymaster is IPaymaster {
    SubscriptionManager public subscriptionManager;

    /**
     * @dev Initializes the paymaster with a reference to the SubscriptionManager.
     * @param _subscriptionManager The address of the SubscriptionManager contract used for validating subscriptions.
     */
    constructor(SubscriptionManager _subscriptionManager) {
        subscriptionManager = _subscriptionManager;
    }

    /**
     * @notice Validates the UserOperation to check if the user has an active subscription.
     * @dev This function is called during the pre-operation phase to verify that the user meets the sponsorship criteria.
     * @param userOp The UserOperation containing transaction details.
     * @param userOpHash A unique hash representing the UserOperation.
     * @param requiredPreFund The required prefund amount for the operation.
     * @return context A context value that will be passed to the postOp function.
     * @return validationData Validation data to be used by the paymaster.
     */
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 requiredPreFund
    ) external view returns (bytes memory context, uint256 validationData) {
        uint256 tokenId = /* Extract the subscription token ID from the userOp */;

        // Verify that the user’s subscription is valid
        require(
            subscriptionManager.isSubscriptionValid(tokenId),
            "CustomPaymaster: Subscription is not valid or has expired"
        );

        // Prepare context data for post-operation
        context = abi.encode(userOpHash, tokenId);
        validationData = 0; // Adjust validationData as per requirements

        return (context, validationData);
    }

    /**
     * @notice Handles post-operation updates, including cross-chain subscription status updates if necessary.
     * @dev This function is called after the user’s operation to process any remaining tasks, such as updating the user's
     *      subscription data across chains if the operation was successful.
     * @param mode The result of the operation (e.g., succeeded, reverted).
     * @param context The context data returned from validatePaymasterUserOp.
     * @param actualGasCost The actual gas cost incurred during the operation.
     */
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external {
        (bytes32 userOpHash, uint256 tokenId) = abi.decode(context, (bytes32, uint256));

        // Ensure that the operation was called by the EntryPoint
        require(msg.sender == /* EntryPoint address */, "CustomPaymaster: Invalid sender");

        // If successful, update the subscription status as needed
        if (mode == PostOpMode.opSucceeded) {
            subscriptionManager.updateSubscriptionData(tokenId);

            // Perform cross-chain update using LayerZero OApp protocol if necessary
            if (/* cross-chain condition */) {
                // Call the LayerZero OApp protocol for cross-chain subscription updates
            }
        }
    }

    // Optional: Define a preOp function if additional pre-operation handling is required
    // function preOp(PreOpMode mode, bytes calldata context, uint256 actualGasCost) external {}
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// CustomPaymaster.sol:

// Role: Manages gas fee sponsorship by verifying subscription status and paying fees.
// Details: Verifies that a user has an active subscription in the pre-op phase, covers the gas fees if conditions are met, and updates the user’s subscription status in the post-op phase.
// Relationship:
// Interacts with SubscriptionManager to validate subscriptions.
// Uses LayerZero OApp protocol for cross-chain subscription updates when needed.
// Uses helper functions from PaymasterHelper.sol.

import "@account-abstraction/contracts/interfaces/IPaymaster.sol";

contract Paymaster is IPaymaster {
    function validatePaymasterUserOp(
        UserOperation calldata,
        bytes32,
        uint256
    ) external pure returns (bytes memory context, uint256 validationData) {
        context = new bytes(0);
        validationData = 0;
    }

    /**
     * post-operation handler.
     * Must verify sender is the entryPoint
     * @param mode enum with the following options:
     *      opSucceeded - user operation succeeded.
     *      opReverted  - user op reverted. still has to pay for gas.
     *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
     *                       Now this is the 2nd call, after user's op was deliberately reverted.
     * @param context - the context value returned by validatePaymasterUserOp
     * @param actualGasCost - actual gas used so far (without this postOp call).
     */
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external {}

    //? Is it a well-know template to define preOp function in the paymaster?
    // function preOp(PreOpMode mode, bytes calldata context, uint256 actualGasCost) external {}
}

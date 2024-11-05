// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SubscriptionNFT
 * @dev A contract for managing user subscriptions represented as ERC-721 NFTs.
 *
 * This contract represents user subscriptions as non-fungible tokens (NFTs) under the ERC-721 standard. Each subscription
 * is minted as an NFT, providing a unique, tradable token that serves as proof of the subscription. Each NFT contains
 * metadata pertinent to the subscription, such as start and end dates, payment details, remaining balance, and sponsored
 * addresses.
 *
 * ## Purpose
 * The primary purpose of this contract is to manage and represent gas sponsorship subscriptions as NFTs. By using the ERC-721
 * standard, subscriptions are verifiable on-chain, transferable, and can store key subscription information within each token.
 * This design supports:
 * - **Ownership** of subscriptions, with NFTs representing a user's specific subscription instance, allowing for transparent
 *   on-chain verification and transferability.
 * - **Metadata storage** for each subscription, including details such as start and end dates, payment method, paid amount,
 *   remaining balance (tracked by `remainingAmount`), and sponsored addresses.
 * - **Interoperability** with other contracts, such as `SubscriptionManager`, which reads and updates subscription data.
 *
 * ## Contract Components
 * - **ERC-721 Functionality**: Uses OpenZeppelin’s ERC-721 implementation to support NFT minting, ownership, and transfers.
 * - **Subscription Management**: Stores subscription details in a `Subscription` struct, with functions to retrieve, update,
 *   and manage each subscription instance.
 * - **Ownership Controls**: Restricts certain functions, such as subscription minting, to the contract owner, ensuring controlled issuance.
 *
 * ## Relationship with Other Contracts
 * - **SubscriptionManager.sol**: The `SubscriptionManager` contract interacts with `SubscriptionNFT` to verify and update
 *   active subscriptions. It plays a central role in deducting fees from the `remainingAmount` on each transaction,
 *   thereby managing the subscription’s balance as gas fees are sponsored.
 *
 * @notice This contract is a core component of a gas sponsorship platform that allows users to purchase subscriptions
 *         for gas fee coverage across multiple chains. Each subscription NFT stores critical data for cross-chain gas
 *         sponsorship management.
 */
contract SubscriptionNFT is ERC721, Ownable {
    /// Represents each user's subscription data
    struct Subscription {
        uint256 startDate; ///< Start date of the subscription in Unix timestamp
        uint256 endDate; ///< End date of the subscription in Unix timestamp
        address paymentToken; ///< Address of the token used for the subscription payment
        uint256 paidAmount; ///< Total amount of tokens paid at subscription purchase
        uint256 remainingAmount; ///< Remaining amount of tokens after transaction fees are deducted
        address[] sponsoredAddresses; ///< List of addresses covered under this subscription for gas sponsorship
    }

    /// Mapping from token ID to Subscription data
    mapping(uint256 => Subscription) public subscriptions;

    address public gasVault;

    /// Counter to generate unique subscription token IDs
    uint256 private _tokenIdCounter;

    /**
     * @dev Emitted when a new subscription is created.
     * @param tokenId Unique token ID representing the subscription
     * @param subscriber Address of the user who purchased the subscription
     * @param startDate Start date of the subscription
     * @param endDate End date of the subscription
     * @param paymentToken Address of the token used for the subscription payment
     * @param amountPaid Total amount of tokens paid for the subscription
     */
    event SubscriptionMinted(
        uint256 indexed tokenId,
        address indexed subscriber,
        uint256 startDate,
        uint256 endDate,
        address paymentToken,
        uint256 amountPaid
    );

    event SubscriptionReduced(
        uint256 indexed tokenId,
        uint256 amountReduced,
        uint256 newRemainingAmount
    );
    event SubscriptionIncreased(
        uint256 indexed tokenId,
        uint256 amountIncreased,
        uint256 newRemainingAmount
    );
    event SponsoredAddressAdded(uint256 indexed tokenId, address addedAddress);
    event SponsoredAddressRemoved(
        uint256 indexed tokenId,
        address removedAddress
    );
    event SubscriptionExtended(
        uint256 indexed tokenId,
        uint256 additionalDays,
        uint256 newEndDate
    );
    event SubscriptionUpdated(
        uint256 indexed tokenId,
        uint256 additionalDays,
        uint256 amountAdded,
        address[] newSponsoredAddresses
    );

    modifier onlyTokenOwner(uint256 tokenId) {
        require(
            ownerOf(tokenId) == msg.sender,
            "SubscriptionNFT: Caller is not the token owner"
        );
        _;
    }

    constructor() ERC721("SubscriptionNFT", "SUBNFT") Ownable(_msgSender()) {}

    /**
     * @dev Mints a new subscription NFT for a user.
     * @param subscriber The address of the user purchasing the subscription.
     * @param startDate The start date of the subscription (as a Unix timestamp).
     * @param endDate The end date of the subscription (as a Unix timestamp).
     * @param paymentToken The address of the token used for payment.
     * @param paidAmount The amount of tokens paid for the subscription.
     * @param sponsoredAddresses The addresses to be sponsored under this subscription.
     * @return tokenId The token ID of the newly minted subscription NFT.
     *
     * @dev The `remainingAmount` will be initially set to the `paidAmount`,
     * and will be deducted by SubscriptionManager as transactions occur.
     */
    function mintSubscription(
        address subscriber,
        uint256 startDate,
        uint256 endDate,
        address paymentToken,
        uint256 paidAmount,
        address[] calldata sponsoredAddresses
    ) external onlyOwner returns (uint256) {
        // ?
        // Payment with smart wallet?
        // Pay before calling this function
        // IERC20(paymentToken).transferFrom(subscriber, gasVault, paidAmount);
        // Native payment?
        // A vals smart wallet as payments destination?

        uint256 tokenId = ++_tokenIdCounter;

        // Store subscription details
        subscriptions[tokenId] = Subscription({
            startDate: startDate,
            endDate: endDate,
            paymentToken: paymentToken,
            paidAmount: paidAmount,
            remainingAmount: paidAmount,
            sponsoredAddresses: sponsoredAddresses
        });

        // Mint the NFT to the subscriber
        _safeMint(subscriber, tokenId);

        emit SubscriptionMinted(
            tokenId,
            subscriber,
            startDate,
            endDate,
            paymentToken,
            paidAmount
        );

        return tokenId;
    }
    // function giftSubscription()

    /**
     * @dev Checks if a subscription is still active.
     * @param tokenId The token ID of the subscription NFT.
     * @return bool True if the subscription is active, false otherwise.
     */
    function isSubscriptionActive(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "SubscriptionNFT: Token ID does not exist");

        Subscription memory subscription = subscriptions[tokenId];
        return (subscription.remainingAmount > 0 &&
            block.timestamp >= subscription.startDate &&
            block.timestamp <= subscription.endDate);
    }

    /**
     * @notice Reduces the `remainingAmount` of tokens for a given subscription.
     * @param tokenId The unique token ID of the subscription NFT.
     * @param amountReduced Amount to deduct from the `remainingAmount`.
     * @dev Throws if the subscription is expired or balance is insufficient.
     */
    function reduceRemainingAmount(
        uint256 tokenId,
        uint256 amountReduced
    ) external onlyOwner {
        require(
            isSubscriptionActive(tokenId),
            "SubscriptionNFT: Subscription is not active"
        );

        Subscription storage subscription = subscriptions[tokenId];
        require(
            subscription.remainingAmount >= amountReduced,
            "SubscriptionNFT: Insufficient remaining amount"
        );
        subscription.remainingAmount -= amountReduced;

        emit SubscriptionReduced(
            tokenId,
            amountReduced,
            subscription.remainingAmount
        );
    }

    /**
     * @notice Increases the `remainingAmount` of tokens for a given subscription.
     * @param tokenId The unique token ID of the subscription NFT.
     * @param amountAdded Amount to add to the `remainingAmount`.
     */
    function increaseRemainingAmount(
        uint256 tokenId,
        uint256 amountAdded
    ) external onlyTokenOwner(tokenId) {
        require(_exists(tokenId), "SubscriptionNFT: Token ID does not exist");

        Subscription storage subscription = subscriptions[tokenId];
        subscription.paidAmount += amountAdded;
        subscription.remainingAmount += amountAdded;

        emit SubscriptionIncreased(
            tokenId,
            amountAdded,
            subscription.remainingAmount
        );
    }

    /**
     * @notice Adds a new address to the `sponsoredAddresses` array for a given subscription.
     * @param tokenId The unique token ID of the subscription NFT.
     * @param newAddress The address to be added to the sponsored list.
     */
    function addSponsoredAddress(
        uint256 tokenId,
        address newAddress
    ) external onlyTokenOwner(tokenId) {
        require(_exists(tokenId), "SubscriptionNFT: Token ID does not exist");

        subscriptions[tokenId].sponsoredAddresses.push(newAddress);

        emit SponsoredAddressAdded(tokenId, newAddress);
    }

    /**
     * @notice Removes an address from the `sponsoredAddresses` array for a given subscription.
     * @param tokenId The unique token ID of the subscription NFT.
     * @param addressToRemove The address to be removed from the sponsored list.
     */
    function removeSponsoredAddress(
        uint256 tokenId,
        address addressToRemove
    ) external onlyTokenOwner(tokenId) {
        require(_exists(tokenId), "SubscriptionNFT: Token ID does not exist");

        address[] storage addresses = subscriptions[tokenId].sponsoredAddresses;
        uint256 length = addresses.length;
        for (uint256 i = 0; i < length; i++) {
            if (addresses[i] == addressToRemove) {
                addresses[i] = addresses[length - 1];
                addresses.pop();

                emit SponsoredAddressRemoved(tokenId, addressToRemove);
                return;
            }
        }
        revert("SubscriptionNFT: Address not found in sponsored list");
    }

    /**
     * @notice Extends the end date of a subscription by a given number of days.
     * @param tokenId The unique token ID of the subscription NFT.
     * @param additionalDays Number of days to extend the subscription.
     */
    function extendSubscriptionTime(
        uint256 tokenId,
        uint256 additionalDays
    ) external onlyTokenOwner(tokenId) {
        require(_exists(tokenId), "SubscriptionNFT: Token ID does not exist");

        Subscription storage subscription = subscriptions[tokenId];
        subscription.endDate += additionalDays * 1 days;

        emit SubscriptionExtended(
            tokenId,
            additionalDays,
            subscription.endDate
        );
    }

    /**
     * @notice Updates a subscription by modifying sponsored addresses, extending time, and adding tokens.
     * @param tokenId The unique token ID of the subscription NFT.
     * @param newSponsoredAddresses Array of addresses to replace the current sponsored addresses.
     * @param additionalDays Number of days to extend the subscription.
     * @param amountAdded Amount of tokens to add to the remaining balance.
     */
    function updateSubscription(
        uint256 tokenId,
        address[] calldata newSponsoredAddresses,
        uint256 additionalDays,
        uint256 amountAdded
    ) external onlyTokenOwner(tokenId) {
        require(_exists(tokenId), "SubscriptionNFT: Token ID does not exist");

        Subscription storage subscription = subscriptions[tokenId];

        // Update sponsored addresses
        delete subscription.sponsoredAddresses;
        for (uint256 i = 0; i < newSponsoredAddresses.length; i++) {
            subscription.sponsoredAddresses.push(newSponsoredAddresses[i]);
        }

        // Extend subscription time
        subscription.endDate += additionalDays * 1 days;

        // Increase remaining balance
        subscription.remainingAmount += amountAdded;

        emit SubscriptionUpdated(
            tokenId,
            additionalDays,
            subscription.remainingAmount,
            newSponsoredAddresses
        );
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return subscriptions[tokenId].startDate != 0;
    }
}

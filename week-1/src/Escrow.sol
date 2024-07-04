// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Escrow Contract
/// @author vipineth
/// @notice A contract for creating and managing escrows for ERC20 tokens
/// @dev Uses SafeERC20 for safe token transfers
contract Escrow {
    using SafeERC20 for IERC20;

    uint256 constant ESCROW_TIME = 3 days;
    /// @notice The counter for the escrow IDs
    uint256 escrowCounter;

    /// @notice Mapping to store escrow data
    mapping(uint256 => EscrowData) public escrows;

    /// @notice Mapping to store escrow IDs for each sender
    mapping(address => uint256[]) public senderEscrows;

    /// @notice Mapping to store escrow IDs for each recipient
    mapping(address => uint256[]) public recipientEscrows;

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed token,
        address indexed sender,
        address recipient,
        uint256 amount,
        uint256 releaseTime
    );

    event Withdrawn(
        uint256 indexed escrowId,
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    error EscrowTimeNotPassed();
    error EscrowAlreadyReleased();
    error InvalidAddress();
    error InvalidAmount();
    error InsufficientBalance();
    error EscrowDoesNotExist();
    error NotRecipient();

    constructor() {}

    struct EscrowData {
        address token;
        address sender;
        address recipient;
        uint256 amount;
        uint256 releaseTime;
        bool isReleased;
    }

    /// @notice Creates a new escrow
    /// @param _token The address of the ERC20 token
    /// @param _recipient The address of the recipient
    /// @param _amount The amount of tokens to be held in escrow
    function createEscrow(
        address _token,
        address _recipient,
        uint256 _amount
    ) external {
        if (_recipient == address(0)) {
            revert InvalidAddress();
        }

        if (_amount == 0) {
            revert InvalidAmount();
        }

        if (IERC20(_token).balanceOf(msg.sender) < _amount) {
            revert InsufficientBalance();
        }

        uint256 releaseTime = block.timestamp + ESCROW_TIME;

        escrows[escrowCounter] = EscrowData({
            token: _token,
            sender: msg.sender,
            recipient: _recipient,
            amount: _amount,
            releaseTime: releaseTime,
            isReleased: false
        });

        senderEscrows[msg.sender].push(escrowCounter);
        recipientEscrows[_recipient].push(escrowCounter);

        escrowCounter = escrowCounter + 1;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit EscrowCreated(
            escrowCounter - 1,
            _token,
            msg.sender,
            _recipient,
            _amount,
            releaseTime
        );
    }

    /// @notice Withdraws tokens from an escrow
    /// @param _escrowId The ID of the escrow to withdraw from
    function withdraw(uint256 _escrowId) external {
        if (_escrowId >= escrowCounter) {
            revert EscrowDoesNotExist();
        }

        EscrowData storage escrow = escrows[_escrowId];

        if (block.timestamp < escrow.releaseTime) {
            revert EscrowTimeNotPassed();
        }

        if (msg.sender != escrow.recipient) {
            revert NotRecipient();
        }

        if (escrow.isReleased) {
            revert EscrowAlreadyReleased();
        }

        /// @dev Set the escrow as released before transferring the tokens to avoid the reentrancy attack
        escrow.isReleased = true;

        IERC20(escrow.token).safeTransfer(escrow.recipient, escrow.amount);

        emit Withdrawn(
            _escrowId,
            escrow.sender,
            escrow.recipient,
            escrow.amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Milestone-Based Escrow System
 * @author Abinash
 * @notice A secure protocol for milestone-based service payments with integrated dispute resolution.
 * @dev This contract uses a state-machine pattern and implements the Pull-over-Push 
 * pattern to prevent Denial of Service and reentrancy attacks.
 */
contract Escrow is Ownable, ReentrancyGuard {
    
    enum Status { AwaitingPayment, InProgress, Disputed, Completed, Canceled, Refunded }

    struct Deal {
        address payer;
        address payee;
        uint256 totalBalance;
        uint256 totalMilestones;
        uint8 currentMilestone;
        Status status;
    }

    struct Milestone {
        string description;
        uint256 amount;
        bool isCompleted;
    }

    struct Dispute {
        uint256 dealId;
        address raisor;
        string reason;
    }

    struct DealWithMilestones {
        uint256 dealId;
        Deal dealData;
        Milestone[] milestoneData;
    }

    // State Variables
    uint256 public dealCount;
    mapping(uint256 => Deal) public deals;
    mapping(address => uint256[]) public userDeals;
    mapping(uint256 => mapping(uint256 => Milestone)) public milestones;
    mapping(uint256 => Dispute) public disputeLogs;

    /** 
     * @dev PULL LOGIC: Ledger to track funds owed to users. 
     * This prevents gas-limit DoS and reentrancy during state transitions.
     */
    mapping(address => uint256) public pendingWithdrawals;

    // Events
    event DealCreated(uint256 indexed dealId, address indexed payee, address indexed payer, uint256 totalBalance);
    event MilestoneCompleted(uint256 indexed dealId, uint256 indexed milestoneId, uint256 amountReleased);
    event DealCompleted(uint256 indexed dealId, address indexed payee, address indexed payer, uint256 totalBalance);
    event DisputeRaised(address indexed raisor, uint256 indexed dealId, string reason);
    event DisputeResolved(uint256 indexed dealId);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event DealCanceled(uint256 indexed dealId,address indexed payer, uint256 refundedAmount);
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Allows users to pull their funds from the contract.
     * @dev Implements the Checks-Effects-Interactions pattern.
     */
    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");

        // Effect: Reset balance before interaction
        pendingWithdrawals[msg.sender] = 0;

        // Interaction: External transfer
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal transfer failed");

        emit FundsWithdrawn(msg.sender, amount);
    }

    function createDeal(
        address _payee, 
        string[] memory _description, 
        uint256[] memory _amount
    ) external nonReentrant payable {
        require(_description.length == _amount.length, "Arrays length mismatch");
        require(_amount.length <= 20, "Too many milestones");
        
        uint256 total = 0;
        for (uint i = 0; i < _amount.length; i++) {
            total += _amount[i];
        }
        require(msg.value == total, "Sent value does not match milestones");

        dealCount++;
        deals[dealCount] = Deal({
            payer: msg.sender,
            payee: _payee,
            totalBalance: msg.value,
            totalMilestones: _amount.length,
            currentMilestone: 0,
            status: Status.InProgress
        });

        for (uint i = 0; i < _amount.length; i++) {
            milestones[dealCount][i] = Milestone({
                description: _description[i],
                amount: _amount[i],
                isCompleted: false
            });
        }

        userDeals[msg.sender].push(dealCount);
        userDeals[_payee].push(dealCount);

        emit DealCreated(dealCount, _payee, msg.sender, msg.value);
    }

    function completeMilestone(uint256 _dealId, uint256 _milestoneId) external nonReentrant {
        Deal storage deal = deals[_dealId];
        Milestone storage milestone = milestones[_dealId][_milestoneId];

        require(deal.totalMilestones > _milestoneId, "Invalid milestone ID");
        require(deal.payer == msg.sender, "Not authorized");
        require(!milestone.isCompleted, "Milestone already completed");
        require(deal.status == Status.InProgress, "Deal not active");

        uint256 amount = milestone.amount;
        require(deal.totalBalance >= amount, "Insufficient deal balance");

        // Effects
        milestone.isCompleted = true;
        deal.currentMilestone += 1;
        deal.totalBalance -= amount;

        // Pull Logic: Credit the payee instead of pushing ETH
        pendingWithdrawals[deal.payee] += amount;

        emit MilestoneCompleted(_dealId, _milestoneId, amount);
    }

    function completeDeal(uint256 _dealId) external nonReentrant {
        Deal storage deal = deals[_dealId];
        require(deal.payer == msg.sender, "Not authorized");
        require(deal.totalMilestones == deal.currentMilestone, "Milestones pending");
        require(deal.status == Status.InProgress, "Deal not active");

        uint256 remaining = deal.totalBalance;
        
        // Effects
        deal.status = Status.Completed;
        deal.totalBalance = 0;

        if (remaining > 0) {
            pendingWithdrawals[deal.payee] += remaining;
        }

        emit DealCompleted(_dealId, deal.payee, deal.payer, remaining);
    }

    function raisedDispute(uint256 _dealId, string calldata _reason) external {
        Deal storage deal = deals[_dealId];
        require(deal.payee == msg.sender || deal.payer == msg.sender, "Not authorized");
        require(deal.status == Status.InProgress || deal.status == Status.AwaitingPayment, "Deal should be in Progress state");

        deal.status = Status.Disputed;
        disputeLogs[_dealId] = Dispute({
            dealId: _dealId,
            raisor: msg.sender,
            reason: _reason
        });

        emit DisputeRaised(msg.sender, _dealId, _reason);
    }

    function resolveDispute(
        uint256 _dealId, 
        uint256 _payerAmount, 
        uint256 _payeeAmount
    ) external onlyOwner nonReentrant {
        Deal storage deal = deals[_dealId];
        require(deal.status == Status.Disputed, "Not in dispute");
        require(_payerAmount + _payeeAmount == deal.totalBalance, "Math mismatch");

        // Effects
        deal.totalBalance = 0;
        deal.status = Status.Refunded;
          
        if (_payerAmount > 0) {
            pendingWithdrawals[deal.payer] += _payerAmount;
        }
        if (_payeeAmount > 0) {
            pendingWithdrawals[deal.payee] += _payeeAmount;
        }

        emit DisputeResolved(_dealId); 
    }

    function cancelDeal(uint256 _dealId) external nonReentrant {
        Deal storage deal = deals[_dealId];
        require(deal.payee == msg.sender || deal.payer == msg.sender, "Not authorized");
        require(deal.status == Status.InProgress, "Only cancelable during InProgress state");
        require(deal.currentMilestone == 0, "Work already started");
        
        uint256 refundAmount = deal.totalBalance;

        // Effects
        deal.status = Status.Canceled;
        deal.totalBalance = 0;

        pendingWithdrawals[deal.payer] += refundAmount;

        emit DealCanceled(_dealId, deal.payer, refundAmount);
    }

    // GETTERS

    function getDeal(uint256 _dealId) external view returns (Deal memory) {
        return deals[_dealId];
    }

    function getMilestones(uint256 _dealId) external view returns (Milestone[] memory) {
        uint256 total = deals[_dealId].totalMilestones;
        Milestone[] memory milestoneList = new Milestone[](total);
        for (uint256 i = 0; i < total; i++) {
            milestoneList[i] = milestones[_dealId][i];
        }
        return milestoneList;
    }

    function getFullDealsByUser(address _user) external view returns (DealWithMilestones[] memory) {
        uint256[] memory ids = userDeals[_user];
        DealWithMilestones[] memory results = new DealWithMilestones[](ids.length);
        
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 totalM = deals[id].totalMilestones;
            Milestone[] memory mList = new Milestone[](totalM);
            for (uint256 j = 0; j < totalM; j++) {
                mList[j] = milestones[id][j];
            }
            results[i] = DealWithMilestones(id, deals[id], mList);
        }
        return results;
    }
}
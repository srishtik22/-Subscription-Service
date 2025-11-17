// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Decentralized Subscription Service
 * @dev A blockchain-based subscription management system for Web3 services
 * @author Your Name
 */
contract Project {
    
    // Subscription plan types
    enum PlanType { MONTHLY, QUARTERLY, YEARLY }
    
    // Plan structure
    struct Plan {
        uint256 price;
        uint256 duration;
        bool isActive;
    }
    
    // Subscription structure
    struct Subscription {
        PlanType planType;
        uint256 endTime;
        bool isActive;
    }
    
    // State variables
    address public owner;
    mapping(PlanType => Plan) public plans;
    mapping(address => Subscription) public subscriptions;
    uint256 public totalSubscribers;
    uint256 public gracePeriod = 3 days;
    
    // Events
    event Subscribed(address indexed user, PlanType planType, uint256 endTime);
    event SubscriptionRenewed(address indexed user, uint256 newEndTime);
    event SubscriptionCancelled(address indexed user);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    modifier hasActiveSubscription() {
        require(isSubscriptionActive(msg.sender), "No active subscription");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        // Initialize subscription plans
        plans[PlanType.MONTHLY] = Plan({
            price: 0.01 ether,
            duration: 30 days,
            isActive: true
        });
        
        plans[PlanType.QUARTERLY] = Plan({
            price: 0.025 ether,
            duration: 90 days,
            isActive: true
        });
        
        plans[PlanType.YEARLY] = Plan({
            price: 0.1 ether,
            duration: 365 days,
            isActive: true
        });
    }
    
    /**
     * @dev Core Function 1: Subscribe to a plan
     * @param _planType The type of subscription plan to purchase
     */
    function subscribe(PlanType _planType) external payable {
        Plan memory plan = plans[_planType];
        
        require(plan.isActive, "Plan is not active");
        require(!isSubscriptionActive(msg.sender), "Already have active subscription");
        require(msg.value >= plan.price, "Insufficient payment");
        
        uint256 endTime = block.timestamp + plan.duration;
        
        subscriptions[msg.sender] = Subscription({
            planType: _planType,
            endTime: endTime,
            isActive: true
        });
        
        totalSubscribers++;
        
        // Refund excess payment
        if (msg.value > plan.price) {
            payable(msg.sender).transfer(msg.value - plan.price);
        }
        
        emit Subscribed(msg.sender, _planType, endTime);
    }
    
    /**
     * @dev Core Function 2: Renew existing subscription
     */
    function renewSubscription() external payable hasActiveSubscription {
        Subscription storage sub = subscriptions[msg.sender];
        Plan memory plan = plans[sub.planType];
        
        require(plan.isActive, "Plan no longer available");
        require(msg.value >= plan.price, "Insufficient payment");
        
        // Extend from current end time
        sub.endTime = sub.endTime + plan.duration;
        
        // Refund excess payment
        if (msg.value > plan.price) {
            payable(msg.sender).transfer(msg.value - plan.price);
        }
        
        emit SubscriptionRenewed(msg.sender, sub.endTime);
    }
    
    /**
     * @dev Core Function 3: Cancel subscription
     */
    function cancelSubscription() external hasActiveSubscription {
        Subscription storage sub = subscriptions[msg.sender];
        sub.isActive = false;
        
        emit SubscriptionCancelled(msg.sender);
    }
    
    /**
     * @dev Check if user has an active subscription
     * @param _user Address of the user to check
     * @return bool True if subscription is active
     */
    function isSubscriptionActive(address _user) public view returns (bool) {
        Subscription memory sub = subscriptions[_user];
        return sub.isActive && block.timestamp <= sub.endTime;
    }
    
    /**
     * @dev Check if user has access (including grace period)
     * @param _user Address of the user to check
     * @return bool True if user has access
     */
    function hasAccess(address _user) public view returns (bool) {
        Subscription memory sub = subscriptions[_user];
        
        if (!sub.isActive) {
            return false;
        }
        
        // Check if within subscription period or grace period
        return block.timestamp <= sub.endTime + gracePeriod;
    }
    
    /**
     * @dev Get subscription details for a user
     * @param _user Address of the user
     * @return planType Type of subscription plan
     * @return endTime Timestamp when subscription ends
     * @return isActive Whether subscription is active
     * @return daysRemaining Days remaining in subscription
     */
    function getSubscriptionDetails(address _user) external view returns (
        PlanType planType,
        uint256 endTime,
        bool isActive,
        uint256 daysRemaining
    ) {
        Subscription memory sub = subscriptions[_user];
        
        uint256 remaining = 0;
        if (sub.endTime > block.timestamp) {
            remaining = (sub.endTime - block.timestamp) / 1 days;
        }
        
        return (sub.planType, sub.endTime, sub.isActive, remaining);
    }
    
    /**
     * @dev Update plan details (Owner only)
     * @param _planType Type of plan to update
     * @param _price New price for the plan
     * @param _duration New duration for the plan
     * @param _isActive Whether plan is active
     */
    function updatePlan(
        PlanType _planType,
        uint256 _price,
        uint256 _duration,
        bool _isActive
    ) external onlyOwner {
        plans[_planType] = Plan({
            price: _price,
            duration: _duration,
            isActive: _isActive
        });
    }
    
    /**
     * @dev Withdraw contract balance (Owner only)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner).transfer(balance);
    }
    
    /**
     * @dev Get plan details
     * @param _planType Type of plan
     * @return price Price of the plan
     * @return duration Duration of the plan in seconds
     * @return isActive Whether plan is active
     */
    function getPlanDetails(PlanType _planType) external view returns (
        uint256 price,
        uint256 duration,
        bool isActive
    ) {
        Plan memory plan = plans[_planType];
        return (plan.price, plan.duration, plan.isActive);
    }
    
    // Fallback function to receive Ether
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title KYCVerification + PredictionMarket Integrated Contract
 * @dev Combines KYC verification and prediction market functionality.
 */
contract KYCVerifiedPredictionMarket {
    // KYC Part

    address public owner;

    enum VerificationStatus { Unverified, Pending, Verified, Rejected }

    struct Customer {
        address customerAddress;
        string customerName;
        string customerDataHash;
        VerificationStatus status;
        uint256 verificationTimestamp;
        string rejectionReason;
    }

    mapping(address => Customer) public customers;
    mapping(address => bool) public verifiers;

    address[] private customerAddresses;

    uint256 public customerCount;
    uint256 public verifierCount;

    // Prediction Market Part

    struct Market {
        string description;
        uint256 endTime;
        bool resolved;
        bool outcome;
        address oracle;
        uint256 totalYesShares;
        uint256 totalNoShares;
        uint256 totalYesStaked;
        uint256 totalNoStaked;
        mapping(address => uint256) yesShares;
        mapping(address => uint256) noShares;
    }

    mapping(uint256 => Market) public markets;
    uint256 public marketCount;
    uint256 public fee = 1; // 1% fee

    // Events KYC
    event CustomerRegistered(address indexed customerAddress, string customerName);
    event KYCVerified(address indexed customerAddress, address indexed verifier);
    event KYCRejected(address indexed customerAddress, address indexed verifier, string reason);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event KYCResubmitted(address indexed customerAddress, string newHash);
    event CustomerNameChanged(address indexed customerAddress, string newName);

    // Events Prediction Market
    event MarketCreated(uint256 indexed marketId, string description, uint256 endTime, address oracle);
    event SharesPurchased(uint256 indexed marketId, address indexed buyer, bool isYes, uint256 amount);
    event MarketResolved(uint256 indexed marketId, bool outcome);
    event RewardsClaimed(uint256 indexed marketId, address indexed user, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyVerifier() {
        require(verifiers[msg.sender] || msg.sender == owner, "Only verifiers can call this function");
        _;
    }

    modifier onlyVerifiedCustomer() {
        require(customers[msg.sender].status == VerificationStatus.Verified, "KYC not verified");
        _;
    }

    constructor() {
        owner = msg.sender;
        verifiers[msg.sender] = true;
        verifierCount = 1;
    }

    // ========== KYC Functions ==========

    function registerCustomer(string memory _customerName, string memory _customerDataHash) public {
        require(customers[msg.sender].customerAddress == address(0), "Customer already registered");

        customers[msg.sender] = Customer({
            customerAddress: msg.sender,
            customerName: _customerName,
            customerDataHash: _customerDataHash,
            status: VerificationStatus.Pending,
            verificationTimestamp: 0,
            rejectionReason: ""
        });

        customerAddresses.push(msg.sender);
        customerCount++;
        emit CustomerRegistered(msg.sender, _customerName);
    }

    function verifyCustomer(address _customerAddress) public onlyVerifier {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        require(customers[_customerAddress].status == VerificationStatus.Pending, "Not in pending state");

        customers[_customerAddress].status = VerificationStatus.Verified;
        customers[_customerAddress].verificationTimestamp = block.timestamp;

        emit KYCVerified(_customerAddress, msg.sender);
    }

    function rejectCustomer(address _customerAddress, string memory _reason) public onlyVerifier {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        require(customers[_customerAddress].status == VerificationStatus.Pending, "Not in pending state");

        customers[_customerAddress].status = VerificationStatus.Rejected;
        customers[_customerAddress].rejectionReason = _reason;

        emit KYCRejected(_customerAddress, msg.sender, _reason);
    }

    function addVerifier(address _verifierAddress) public onlyOwner {
        require(!verifiers[_verifierAddress], "Already a verifier");

        verifiers[_verifierAddress] = true;
        verifierCount++;

        emit VerifierAdded(_verifierAddress);
    }

    function removeVerifier(address _verifierAddress) public onlyOwner {
        require(verifiers[_verifierAddress], "Not a verifier");
        require(_verifierAddress != owner, "Cannot remove owner");

        verifiers[_verifierAddress] = false;
        verifierCount--;

        emit VerifierRemoved(_verifierAddress);
    }

    function getCustomerStatus(address _customerAddress) public view returns (VerificationStatus) {
        require(customers[_customerAddress].customerAddress != address(0), "Customer not registered");
        return customers[_customerAddress].status;
    }

    function getCustomerDetails(address _customerAddress) public view returns (
        string memory name,
        string memory dataHash,
        VerificationStatus status,
        uint256 timestamp,
        string memory reason
    ) {
        Customer memory c = customers[_customerAddress];
        require(c.customerAddress != address(0), "Customer not registered");
        return (c.customerName, c.customerDataHash, c.status, c.verificationTimestamp, c.rejectionReason);
    }

    function resubmitKYC(string memory _newHash) public {
        require(customers[msg.sender].customerAddress != address(0), "Customer not registered");
        require(customers[msg.sender].status == VerificationStatus.Rejected, "KYC not rejected");

        customers[msg.sender].customerDataHash = _newHash;
        customers[msg.sender].status = VerificationStatus.Pending;
        customers[msg.sender].rejectionReason = "";

        emit KYCResubmitted(msg.sender, _newHash);
    }

    function changeCustomerName(string memory _newName) public {
        require(customers[msg.sender].customerAddress != address(0), "Customer not registered");
        require(customers[msg.sender].status == VerificationStatus.Pending, "Can only change during pending");

        customers[msg.sender].customerName = _newName;
        emit CustomerNameChanged(msg.sender, _newName);
    }

    function getAllCustomerAddresses() public view returns (address[] memory) {
        return customerAddresses;
    }

    function isVerifier(address _addr) public view returns (bool) {
        return verifiers[_addr];
    }

    // ========== Prediction Market Functions ==========

    function createMarket(string memory description, uint256 endTime, address oracle) public onlyOwner {
        require(endTime > block.timestamp, "End time must be in the future");
        require(oracle != address(0), "Invalid oracle address");

        uint256 marketId = marketCount;

        Market storage market = markets[marketId];
        market.description = description;
        market.endTime = endTime;
        market.oracle = oracle;
        market.resolved = false;

        marketCount++;

        emit MarketCreated(marketId, description, endTime, oracle);
    }

    function purchaseShares(uint256 marketId, bool isYes) public payable onlyVerifiedCustomer {
        Market storage market = markets[marketId];

        require(!market.resolved, "Market already resolved");
        require(block.timestamp < market.endTime, "Market closed for betting");
        require(msg.value > 0, "Must send ETH to purchase shares");

        uint256 feeAmount = (msg.value * fee) / 100;
        uint256 stakeAmount = msg.value - feeAmount;

        if (isYes) {
            uint256 shares = calculateShares(stakeAmount, market.totalYesStaked, market.totalYesShares);
            market.yesShares[msg.sender] += shares;
            market.totalYesShares += shares;
            market.totalYesStaked += stakeAmount;
        } else {
            uint256 shares = calculateShares(stakeAmount, market.totalNoStaked, market.totalNoShares);
            market.noShares[msg.sender] += shares;
            market.totalNoShares += shares;
            market.totalNoStaked += stakeAmount;
        }

        // Transfer fee to contract owner
        payable(owner).transfer(feeAmount);

        emit SharesPurchased(marketId, msg.sender, isYes, stakeAmount);
    }

    function resolveMarket(uint256 marketId, bool outcome) public {
        Market storage market = markets[marketId];

        require(msg.sender == market.oracle, "Only oracle can resolve");
        require(!market.resolved, "Market already resolved");
        require(block.timestamp >= market.endTime, "Market not yet closed");

        market.resolved = true;
        market.outcome = outcome;

        emit MarketResolved(marketId, outcome);
    }

    function claimRewards(uint256 marketId) public onlyVerifiedCustomer {
        Market storage market = markets[marketId];

        require(market.resolved, "Market not resolved yet");

        uint256 winningShares;
        uint256 reward = 0;

        if (market.outcome) {
            // Yes was correct
            winningShares = market.yesShares[msg.sender];
            if (winningShares > 0 && market.totalYesShares > 0) {
                reward = (winningShares * (market.totalYesStaked + market.totalNoStaked)) / market.totalYesShares

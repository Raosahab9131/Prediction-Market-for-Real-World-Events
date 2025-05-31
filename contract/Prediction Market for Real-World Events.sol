// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract KYCVerifiedPredictionMarket {
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

    struct MarketOracleHistory {
        uint256 timestamp;
        address oracle;
    }

    struct Market {
        string description;
        uint256 endTime;
        bool resolved;
        bool outcome;
        address oracle;
        MarketOracleHistory[] oracleHistory;
        uint256 totalYesShares;
        uint256 totalNoShares;
        uint256 totalYesStaked;
        uint256 totalNoStaked;
        mapping(address => uint256) yesShares;
        mapping(address => uint256) noShares;
        mapping(address => bool) rewardsClaimed;
        mapping(address => uint256) pendingWithdrawals;
    }

    mapping(address => Customer) public customers;
    mapping(address => bool) public verifiers;
    mapping(address => bool) public blacklisted;
    address[] private customerAddresses;
    uint256 public customerCount;
    uint256 public verifierCount;

    mapping(uint256 => Market) public markets;
    uint256 public marketCount;
    uint256 public fee = 1;
    uint256 public refundGracePeriod = 7 days;

    event CustomerRegistered(address indexed customerAddress, string customerName);
    event KYCVerified(address indexed customerAddress, address indexed verifier);
    event KYCRejected(address indexed customerAddress, address indexed verifier, string reason);
    event KYCStatusChanged(address indexed customerAddress, VerificationStatus newStatus);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event KYCResubmitted(address indexed customerAddress, string newHash);
    event CustomerNameChanged(address indexed customerAddress, string newName);
    event CustomerBlacklisted(address indexed customerAddress);
    event CustomerUnblacklisted(address indexed customerAddress);
    event MarketCreated(uint256 indexed marketId, string description, uint256 endTime, address oracle);
    event SharesPurchased(uint256 indexed marketId, address indexed buyer, bool isYes, uint256 amount);
    event MarketResolved(uint256 indexed marketId, bool outcome);
    event RewardsClaimed(uint256 indexed marketId, address indexed user, uint256 amount);
    event RefundClaimed(uint256 indexed marketId, address indexed user, uint256 amount);
    event OracleUpdated(uint256 indexed marketId, address newOracle);
    event FeeUpdated(uint256 newFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyVerifier() {
        require(verifiers[msg.sender] || msg.sender == owner, "Only verifier");
        _;
    }

    modifier onlyVerifiedCustomer() {
        require(customers[msg.sender].status == VerificationStatus.Verified, "Not verified");
        require(!blacklisted[msg.sender], "Blacklisted");
        _;
    }

    constructor() {
        owner = msg.sender;
        verifiers[msg.sender] = true;
        verifierCount = 1;
    }

    // ======= KYC =======

    function registerCustomer(string memory _name, string memory _hash) public {
        require(customers[msg.sender].customerAddress == address(0), "Already registered");
        require(!blacklisted[msg.sender], "Blacklisted");
        customers[msg.sender] = Customer(msg.sender, _name, _hash, VerificationStatus.Pending, 0, "");
        customerAddresses.push(msg.sender);
        customerCount++;
        emit CustomerRegistered(msg.sender, _name);
        emit KYCStatusChanged(msg.sender, VerificationStatus.Pending);
    }

    function verifyCustomer(address _addr) public onlyVerifier {
        require(customers[_addr].status == VerificationStatus.Pending, "Not pending");
        customers[_addr].status = VerificationStatus.Verified;
        customers[_addr].verificationTimestamp = block.timestamp;
        emit KYCVerified(_addr, msg.sender);
        emit KYCStatusChanged(_addr, VerificationStatus.Verified);
    }

    function rejectCustomer(address _addr, string memory _reason) public onlyVerifier {
        require(customers[_addr].status == VerificationStatus.Pending, "Not pending");
        customers[_addr].status = VerificationStatus.Rejected;
        customers[_addr].rejectionReason = _reason;
        emit KYCRejected(_addr, msg.sender, _reason);
        emit KYCStatusChanged(_addr, VerificationStatus.Rejected);
    }

    function resubmitKYC(string memory _newHash) public {
        require(customers[msg.sender].status == VerificationStatus.Rejected, "Not rejected");
        customers[msg.sender].customerDataHash = _newHash;
        customers[msg.sender].status = VerificationStatus.Pending;
        customers[msg.sender].rejectionReason = "";
        emit KYCResubmitted(msg.sender, _newHash);
        emit KYCStatusChanged(msg.sender, VerificationStatus.Pending);
    }

    function changeCustomerName(string memory _newName) public {
        require(customers[msg.sender].status == VerificationStatus.Pending, "Only in pending");
        customers[msg.sender].customerName = _newName;
        emit CustomerNameChanged(msg.sender, _newName);
    }

    function blacklistCustomer(address _addr) public onlyOwner {
        blacklisted[_addr] = true;
        emit CustomerBlacklisted(_addr);
    }

    function unblacklistCustomer(address _addr) public onlyOwner {
        blacklisted[_addr] = false;
        emit CustomerUnblacklisted(_addr);
    }

    function addVerifier(address _addr) public onlyOwner {
        require(!verifiers[_addr], "Already verifier");
        verifiers[_addr] = true;
        verifierCount++;
        emit VerifierAdded(_addr);
    }

    function removeVerifier(address _addr) public only_

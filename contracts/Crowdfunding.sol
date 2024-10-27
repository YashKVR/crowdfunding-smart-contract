// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Crowdfunding Contract
 * @author Yash KVR
 * @notice Basic implementation of a crowdfunding smart contract
 */
contract Crowdfunding {
    string public s_name;
    string public s_description;
    uint256 public s_goal;
    uint256 public s_deadline;
    address public s_owner;

    enum CampaignState {
        Active,
        Successful,
        Failed
    }

    CampaignState public state;

    struct Tier {
        string name;
        uint256 amount;
        uint256 backers;
    }

    Tier[] public s_tiers;

    modifier onlyOwner() {
        require(msg.sender == s_owner, "Only the owner can call this function");
        _;
    }

    modifier campaignOpen() {
        require(state == CampaignState.Active, "Campaign is not active");
        _;
    }

    constructor(
        string memory _name,
        string memory _description,
        uint256 _goal,
        uint256 _durationInDays
    ) {
        s_name = _name;
        s_description = _description;
        s_goal = _goal;
        s_deadline = block.timestamp + (_durationInDays * 1 days);
        s_owner = msg.sender;
        state = CampaignState.Active;
    }

    function checkAndUpdateCampaignState() internal {
        if (state == CampaignState.Active) {
            if (block.timestamp >= s_deadline) {
                state = address(this).balance >= s_goal
                    ? CampaignState.Successful
                    : CampaignState.Failed;
            } else {
                state = address(this).balance >= s_goal
                    ? CampaignState.Successful
                    : CampaignState.Active;
            }
        }
    }

    /**
     * Funds the smart contract
     * @param _tierIndex accepts amount as per tier index
     */
    function fund(uint256 _tierIndex) public payable campaignOpen {
        require(_tierIndex < s_tiers.length, "Tier does not exist");
        require(msg.value == s_tiers[_tierIndex].amount, "Incorrect amount");

        s_tiers[_tierIndex].backers++;
        checkAndUpdateCampaignState();
    }

    /**
     * @notice Adds a tier to the campaign
     * @param _name Tier name like basic, best etc
     * @param _amount In wei
     */
    function addTier(string memory _name, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        s_tiers.push(Tier(_name, _amount, 0));
    }

    /**
     * @notice Deletes the tier with index as reference
     * @param _index Index of tier to be deleted
     */
    function removeTier(uint256 _index) public onlyOwner {
        require(_index < s_tiers.length, "Tier does not exist");
        s_tiers[_index] = s_tiers[s_tiers.length - 1];
        s_tiers.pop();
    }

    /**
     * Withdraws balance to the deployer/owner
     */
    function withdraw() public onlyOwner {
        checkAndUpdateCampaignState();
        require(state == CampaignState.Successful, "Campaign not successful");

        uint256 balance = address(this).balance;
        require(balance > 0, "No Balance to withdraw");

        payable(s_owner).transfer(balance);
    }

    /**
     * @return Contract balance in wei
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

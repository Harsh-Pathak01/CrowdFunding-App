// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//allows us to deploy the smart contracts for us but allow us to keep 
//track of all those contracts deployed and display them all within the application 

import {Crowdfunding} from "./crowdfunding.sol"; //so that we can deploy that deploy the smart contract in this contract 

contract CrowdfundingFactory{
    address public owner; //owner of the contract    
    bool public paused; //to pause the campaign 

    struct Campaign{
        address campaignAddress; 
        address owner; 
        string name; 
        uint256 creationTime; //creation time of the campaign 
    }

    Campaign[] public campaigns; //to keep track of all the campaigns 

    mapping(address => Campaign[]) public userCampaigns; 

    modifier onlyOwner(){
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    modifier notPaused(){
        require(!paused, "Campaign is paused");
        _;
    }

    constructor(){
        owner = msg.sender; 
    }

    function createCampaign( //function to provide name, description etc
        string memory _name, 
        string memory _description, 
        uint256 _goal, 
        uint256 _durationInDays
   ) external notPaused{ 
        Crowdfunding newCampaign = new Crowdfunding( //deploys a crowdfunding contract 
            msg.sender, //provide it with the information that we need to provide our smart contract with
            _name, 
            _description,
            _goal,
            _durationInDays
        );
        address campaignAddress = address(newCampaign); 

        Campaign memory campaign = Campaign({
            campaignAddress: campaignAddress, 
            owner: msg.sender, 
            name: _name, 
            creationTime: block.timestamp
        });

        campaigns.push(campaign); 
        userCampaigns[msg.sender].push(campaign); 
   }
    function getUserCampaigns(address _user) external view returns(Campaign[] memory){
        return userCampaigns[_user]; //returns campaigns at the address _user 
    }   

    function getAllCampaigns() external view returns(Campaign[] memory){
        return campaigns; //returns all campaings 
    }    
    function togglePause() external onlyOwner{
        paused = !paused; //for pausing and unpausing 
    }
}
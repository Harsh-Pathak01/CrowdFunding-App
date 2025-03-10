// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Crowdfunding{
    string public name;
    string public description; //descriptiopn of campaign
    uint256 public goal; //how much person wants to raise
    uint256 public deadline; 
    address public owner; //wallet address of the owner
    bool public paused; //will tell us if campaign is paused or not 

    enum CampaignState{Active, Successful, Failed} //to keep track of state of the contract
    CampaignState public state; 

    struct Tier{ //to make fixed amount of money thet can be paid by the donater
        string name; 
        uint256 amount; 
        uint256 backers; //no of donators 
    }

    struct Backer{
         uint256 totalContribution; //to keep track of amount funded
         mapping(uint256 => bool) fundedTiers; //uint256 here is an index tier and says if a backer fund index tier 0 then say true else false
    }

    Tier[] public tiers; //to store different payment tiers in the array 
    mapping(address => Backer) public backers; //we put in an address and it will map it back to address of backer and tell their total contrbuition and tiers they've funded

    modifier onlyOwner(){ //add modifers so we dont have to define require command for owner in every function 
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier campaignOpen(){
         require(state == CampaignState.Active, "Campaign is not active");
         _;
    }

    modifier notPaused(){ //modifier for paused 
        require(!paused, "Contract is paused.");
        _;
    }
 
    constructor(
        address _owner,
        string memory _name,
        string memory _description,
        uint256 _goal,
        uint256 _durationInDays //how many days they want campaign to run
    ){
        name = _name;
        description = _description; 
        goal = _goal; 
        deadline = block.timestamp + (_durationInDays * 1 days); 
        //block.timestamp is to get current time + we add duration user wants to keep the campaign for
        owner = _owner; //smart contract deployer
        //set to _owner such that the owner is the one who calls the factory contract and not that the owner is the factory contract  
        state = CampaignState.Active; //campaign state be active by default
    } 

    function checkAndUpdateCampaignState() internal {
        if(state == CampaignState.Active){
            if(block.timestamp >= deadline){
                state = address(this).balance >= goal? CampaignState.Successful : CampaignState.Failed;
            }else{
                state = address(this).balance >= goal? CampaignState.Successful : CampaignState.Active; 
            }
        }
    }

    function fund(uint256 _tierIndex) public payable campaignOpen {
        //require(block.timestamp < deadline, "The campaign has ended"); //So that donators can also fund until the deadline 
        require(_tierIndex < tiers.length, "Invalid tier");
        require(msg.value == tiers[_tierIndex].amount, "Incorrect amount"); //to check if the value donator sends is withing the tier amount 

        tiers[_tierIndex].backers++; //after every donation, no of backers increases
        backers[msg.sender].totalContribution += msg.value; //we update the total contribution by mapping it back to the struct where we made the variable to keep track of the total contribution
        backers[msg.sender].fundedTiers[_tierIndex] = true; //if backer has funded the specific tier then say true helps keep track of backer info and helps to know how much to refund the backer in case a campaign fails 

        checkAndUpdateCampaignState();
    }

    function addTier( //functions to add and remove tiers
        string memory _name,
        uint256 _amount
    )public onlyOwner{ //only owner should be allowed to call this function
        require(_amount > 0, "Amount must be greater than 0");
        tiers.push(Tier(_name,_amount,0)); //adding new tier added to the tier storing array
    }

    function removeTier(uint256 _index) public onlyOwner{ //only owner should be allowed to call this function
        require(_index < tiers.length,"Tier doesn't exist"); //the index added should be in tier array
        tiers[_index] = tiers[tiers.length-1];//-1 because index starts from 0 
        tiers.pop(); //remove the tier
    }

    function withdraw() public onlyOwner {
        checkAndUpdateCampaignState();
        require(state == CampaignState.Successful, "Campaign not successful yet");
        //require(msg.sender == owner, "Only the owner can withdraw");
        require(address(this).balance >= goal, "Goal has not been reached");//owner can only withdraw if the goal amount has been reached, this is used for this function

        uint256 balance = address(this).balance; //will store balance of campaign in this variable
        require(balance > 0, "No balance to withdraw");

        payable(owner).transfer(balance); //transfer balance to owner
    }

    function getContractBalance() public view returns(uint256){ //how much has already been funded (view because its a read function)
        return address(this).balance; //only view function so we read the final balance
    }

    function refund() public{
        checkAndUpdateCampaignState(); //make sure its in the correct state 
        //require(state == CampaignState.Failed, "Refund not available"); //check if campaign has failed or not
        uint256 amount = backers[msg.sender].totalContribution; //stores amount to refund 
        require(amount > 0, "No contribution to refund");

        backers[msg.sender].totalContribution = 0; 
        payable (msg.sender).transfer(amount); //transfer the user the refund amount if the campaign fails
    }

    function hasFunderTier(address _backer, uint256 _tierIndex) public view returns(bool){ //_backer to check which backer and _tierIndex to check which tier they donated to | it is a view function to check if backer has donated
        return backers[_backer].fundedTiers[_tierIndex]; //returns info if the backer has funded the tier or not at the address provided
    }

    function getTiers() public view returns(Tier[] memory){
        return tiers; //gets back data for tiers         
    }

    function togglePause() public onlyOwner{
        paused = !paused; //toggle from paused to unpaused and can only be accessed by the owner  
    }

    function getCampaignStatus() public view returns(CampaignState){  //gets us status of the campaign
        if(state == CampaignState.Active && block.timestamp > deadline){ //checking is campaign is active and past its deadline 
            return address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;
        }
        return state; 
    }

    function extendedDeadline(uint256 _daysToAdd) public onlyOwner campaignOpen{ //function to extend the deadline, takes the days to add from the owner to extend
        //only owner can call this function and only when campaign is open
        deadline += _daysToAdd * 1 days; //no of days to add
    } 
}

//now we create a factory contract (contract that deploys a smart contract to deply our crowdfunding contract
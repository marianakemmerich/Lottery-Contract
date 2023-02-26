pragma solidity ^0.4.17;

contract CampaignFactory {
    // creates a new contract that will be deployed at the blockchain
    address[] public deployedCampaigns;
    function createCampaign(uint minimum) public { // alows a user to create a new instance of  a campaign
    address newCampaign = new Campaign(minimum, msg.sender);
    deployedCampaigns.push(newCampaign);
    } 

    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description; // describes why the request is being created
        uint value; // amount of money that themanager wants to send to the vendor
        address recipient; // address that the money will be sent to
        bool complete; // true if the requet has already been processed
        uint approvalCount; // keeps track of the number of approvals
        mapping(address => bool) approvals; //keps track of whether or not someone has voted on a given request
    }

    Request[] public requests;
    address public manager; // address of the person who's managing this campaign
    uint public minimumContribution; // minimum donation required to be considered a contributor or "approver"
    //address[] public approvers; - list of addresses for every person who has donated money; using mapping instead of arrays
    mapping(address => bool) public approvers;
    uint public approversCount;


    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

    function Campaign(uint minimum, address creator) public { // sets the minimumContribution and the owner
        manager = creator; // who's attempting to create the contract
        minimumContribution = minimum;
    }

    function contribute() public payable { // called when someone wants to donate money to the campaign and become an approver
        require(msg.value > minimumContribution);

        // approvers.push(msg.sender); - adds the donator to the approvers - the method .push is only available to arrays
        approvers[msg.sender] = true;
        approversCount++; // ells how many people have joined in or contributed to the contract
    }

    function createRequest(string description, uint value, address recipient) 
        public restricted {
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalCount: 0
        });

        requests.push(newRequest);
    }

    function approveRequest(uint index) public { // 'index' specifies which request we're attempting to vote yes on
    Request storage request = requests[index];

    // makes sure that the person calling this function has already donated to the contract
    require(approvers[msg.sender]);
    require(!request.approvals[msg.sender]);

    request.approvals[msg.sender] = true; // if the sender calls approval request again they will fail the second require check above
    request.approvalCount++;
    }

    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2)); // more than half the people must approve the request before it can be released
        require(!request.complete);

        request.recipient.transfer(request.value); // sends the money to the recipient
        request.complete = true;
    }
}

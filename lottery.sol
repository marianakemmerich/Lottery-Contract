pragma solidity ^0.4.17;

contract Lottery{
    address public manager;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }
    function enter() public payable { //enters a player into the contract
        require(msg.value > .01 ether);

        players.push(msg.sender);
    }
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    function pickWinner() public restricted { // picks a winner
        uint index = random() % players.length;
        players[index].transfer(this.balance); // verifies if the winner received the amount of money
        players = new address[](0); // resets and empties out the player's array
    }
    modifier restricted() {
        //if the name of the function modifier is added to any other function inside of
        //the contract, the solidity compiler will take all the code out of the function
        //and stick it in where the underscore is
        require(msg.sender == manager);
        _;
    }
    function getPlayers() public view returns (address[]) {
        return players;
    }
}

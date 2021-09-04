pragma solidity ^0.4.26;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract airdropTotal {
    using SafeMath for uint;
    
    mapping(address => uint) usertotal; //用户领取余额
    
    function saveUsertotal(address _user,uint _value)public onlyAI{
        usertotal[_user] = usertotal[_user].add(_value);
    }
    
    function getUsertotal(address _user) public view returns(uint){
        return usertotal[_user];
    }
    
    address[] AIadr; //机器人地址存储
    address public owner;    //管理员地址 
    
    modifier onlyAI(){
        for(uint i=0; i<AIadr.length; i++){
             if(AIadr[i] == msg.sender)
             {uint a = 1;}
        }
        require(a == 1);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _; 
    }
    
    function transferOwer(address newOwner)public ownerOnly{
        owner = newOwner;
    }
    
    //添加AI地址
    function addAIadr(address _AIadr)public ownerOnly{
        AIadr.push(_AIadr);
    }
    
    //移除AI地址
    function delAIadr(address _AIadr)public ownerOnly{
        for(uint i=0; i<AIadr.length; i++ ){
            if(AIadr[i] == _AIadr){
                delete AIadr[i];
                AIadr[i] = AIadr[AIadr.length -1];
                AIadr.length --;
            }
        }
    }
    
    //获取AI地址
    function getAIadr()public view returns(address[]){
        return AIadr;
    }
    
}

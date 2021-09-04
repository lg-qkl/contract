pragma solidity ^0.4.24;

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

contract airdrop{
    using SafeMath for uint;
    
    address public owner;
    address public LG;
    address public LGC;
    uint public LGCrequirement = 10 ;
    address public invite; //邀请关系合约地址
    address public adr01 = 0x0000000000000000000000000000000000000001;
    
    function modifyLGAddr(address newLG_Addr)public ownerOnly{
        LG = newLG_Addr;
    }
    
    function modifyLGCAddr(address newLGC_Addr)public ownerOnly{
        LGC = newLGC_Addr;
    }
    
    function modifyLGCrequirement(uint _LGCrequirement)public ownerOnly{
        LGCrequirement = _LGCrequirement;
    }
    
    constructor(address _LG, address _LGC, address _invite) public {
        LG = _LG;
        LGC = _LGC;
        invite = _invite;
        owner = msg.sender;}
        
    modifier ownerOnly() {
        require(msg.sender == owner);
        _; 
    }
    function transferOwer(address newOwner)public ownerOnly{
        owner = newOwner;
    }
    
    function setinvite(address _invite)public ownerOnly{
        invite = _invite;
    }
        
////////
    uint public AirdropAmount = 8880000000000000000;
    function setAirdropAmount(uint _AirdropAmount)public ownerOnly{
        AirdropAmount = _AirdropAmount;
    }

    mapping(address => uint) public isget;
    
    function getAirdrop(address _inviter) public{
        require(_inviter != msg.sender);
        require(isget[msg.sender] == 0  && IERC20(LGC).balanceOf(msg.sender) >= LGCrequirement );
        isget[msg.sender] = 1 ;
        ///////////以下为邀请机制判断
        address inviter = Invite(invite).getInviter(msg.sender);
        if(inviter == address(0)){  //第一次进入
            Invite(invite).saveInviter(msg.sender,_inviter);
            if(_inviter == adr01){ //自来客
                IERC20(LG).transfer(msg.sender, AirdropAmount);
            }else{//有邀请人
                IERC20(LG).transfer(msg.sender, AirdropAmount);
                IERC20(LG).transfer(_inviter, AirdropAmount.mul(75).div(100));
            }
        }
        if(inviter == adr01){ //自来客
            IERC20(LG).transfer(msg.sender, AirdropAmount);
        }
        if(inviter != address(0) && inviter != adr01){ //有邀请人
            IERC20(LG).transfer(msg.sender, AirdropAmount);
            IERC20(LG).transfer(inviter, AirdropAmount.mul(75).div(100));
        }
        ///////////以上为邀请机制判断
    }
    
    function claim() public ownerOnly{
        uint amount = IERC20(LG).balanceOf(address(this));
        IERC20(LG).transfer(msg.sender, amount);
    }
}


interface IERC20{
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}

interface Invite{
    function saveInviter(address _user,address _inviter) external;
    function getInviter(address _user) external view returns(address);
}
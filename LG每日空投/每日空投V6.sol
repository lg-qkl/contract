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
    
    uint public _adayamount = 200e18; //实时一天的量
    
    mapping(address => uint)  timemap; //用户计时
    mapping(address => uint) public lastHB;//查询结果
    
    ///////////////////////////
    address public owner;
    address public LG;   //LG通证地址
    address public LGC;  //信用分地址
    uint public LGCamount = 10;  //要求多少信用分可使用
    uint public AirdropAmount = 16e17; //单个空投量
    uint public time = 1; //每几天可以领一次
    uint public timeD = 1; //供应间隔(天)
    uint public adayamount = 200e18; //一天的量
    uint public adayTime; //供应计时
    
    function modifyLGAddr(address newLG_Addr)public ownerOnly{
        LG = newLG_Addr;
    }
    function modifyLGCAddr(address newLGC_Addr)public ownerOnly{
        LGC = newLGC_Addr;
    }
    
    constructor(address _LG, address _LGC) public {
        LG = _LG;
        LGC = _LGC;
        owner = msg.sender;
        adayTime = now;
    }
        
    modifier ownerOnly() {
        require(msg.sender == owner);
        _; 
    }
    function transferOwer(address newOwner)public ownerOnly{
        owner = newOwner;
    }
    
    //每几天可以领一次
    function setTime(uint _time) public ownerOnly{
        time = _time;
    }
    
    //供应间隔(天)
    function setTimeD(uint _timeD) public ownerOnly{
        timeD = _timeD;
    }
    
    //单个空投量
    function setAirdropAmount(uint _AirdropAmount)public ownerOnly{
        AirdropAmount = _AirdropAmount;
    }
    
    //一天的量
    function set_adayamount(uint _amount)public ownerOnly{
        adayamount = _amount;
    }
    
    //信用分设定
    function set_LGC(uint _amount)public ownerOnly{
        LGCamount = _amount;
    }
    
    modifier LGCchack() {
        require(IERC20(LGC).balanceOf(msg.sender) >=LGCamount);
        _; 
    }
    
    //////////////////////////////////////    
    
    //供应每日量
    function addDayamount()public {
        require(_adayamount <= AirdropAmount.mul(4)  && now >= adayTime.add(timeD.mul(1 days)) );
        adayTime = now;
        _adayamount = adayamount;
    }
    
    function getAirdrop() public LGCchack{
        require(timemap[msg.sender] < now );
        timemap[msg.sender] = now.add((time.mul(1 days)));
        /////////////////////////////////////////////////////////////
        uint a;
        uint b;
        a = uint (keccak256(abi.encodePacked(now,msg.sender))).mod(10);
        if(a == 0 ){b = a+1;
         }else{b = a;}
        uint c = AirdropAmount.mul(2).mul(b).div(10);
        ////////////////////////////////////////////////////////////////
        _adayamount = _adayamount.sub(c);
        IERC20(LG).transfer(msg.sender, c);
        lastHB[msg.sender] = c;
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
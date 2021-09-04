/**
 *Submitted for verification at hecoinfo.com on 2021-03-08
*/

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
    
    uint public _adayamount = 10e18; //实时一天的量
    
    mapping(address => uint)  timemap; //用户计时
    mapping(address => uint) public lastHB;//查询结果
    mapping(address=> uint) public Usertotal;  //预挖存储

    
    ///////////////////////////
    address public owner;
    address public LG;
    uint public AirdropAmount = 16e17; //单个空投量
    uint public time = 1; //每几天可以领一次
    uint public timeD = 1; //供应间隔(天)
    uint public _Usertotal= 10e18 ; //存储多少转到帐户
    uint public adayamount = 10e18; //一天的量
    uint public adayTime; //供应计时
    mapping(address => uint) public blacklist; //黑名单
    
    function modifyLGAddr(address newLG_Addr)public ownerOnly{
        LG = newLG_Addr;
    }
    
    constructor(address _LG) public {
        LG = _LG;
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
    
    //存储多少转到帐户
    function set_Usertotal(uint _total)public ownerOnly{
        _Usertotal = _total;
    }
    
    //一天的量
    function set_adayamount(uint _amount)public ownerOnly{
        adayamount = _amount;
    }
    
    //管理员可以对刷单用户删除预挖,并加入黑名单
    function del_Usertotal(address _user)public ownerOnly{
        Usertotal[_user] = 0;
        blacklist[_user] = 1;
    }
    
    //解除黑名单
    function del_blacklist(address _user)public ownerOnly{
        blacklist[_user] = 0;
    }
    
    //////////////////////////////////////    
    
    //供应每日量
    function addDayamount()public {
        require(_adayamount <= AirdropAmount.mul(2)  && now >= adayTime.add(timeD.mul(30 seconds)) );
        adayTime = now;
        _adayamount = adayamount;
    }
    
    function getAirdrop() public{
        require(timemap[msg.sender] < now  && blacklist[msg.sender] != 1);
        timemap[msg.sender] = now.add((time.mul(1 seconds)));
        /////////////////////////////////////////////////////////////
        uint a;
        uint b;
        a = uint (keccak256(abi.encodePacked(now,msg.sender))).mod(10);
        if(a == 0 ){b = a+1;
         }else{b = a;}
        uint c = AirdropAmount.mul(2).mul(b).div(10);
        ////////////////////////////////////////////////////////////////
        
        Usertotal[msg.sender] = Usertotal[msg.sender] .add(c);
        _adayamount = _adayamount.sub(c);
        lastHB[msg.sender] = c;
        
        if(Usertotal[msg.sender] >= _Usertotal){
           ILG(LG).transfer(msg.sender, Usertotal[msg.sender]);
           Usertotal[msg.sender] = 0 ;
        }
    }
    
    function claim() public ownerOnly{
        uint amount = ILG(LG).balanceOf(address(this));
        ILG(LG).transfer(msg.sender, amount);
    }
}


interface ILG{
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}
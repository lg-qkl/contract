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

contract airdropDay{
    using SafeMath for uint;
    
    uint public _adayamount = 800e18; //实时一天的量
    
    mapping(address => uint)  timemap; //用户计时
    
    ///////////////////////////
    address public airdropTotalAdr; //空投累计额合约地址 
    address public owner;
    address public LG;   //LG通证地址
    address public LGC;  //信用分地址
    uint public LGCamount = 10;  //要求多少信用分可使用
    uint public AirdropAmount = 10488880000000000000; //单个空投量
    uint public time = 1; //每几天可以领一次
    uint public timeD = 1; //供应间隔(天)
    uint public adayamount = 1200e18; //一天的量
    uint public adayTime; //供应计时
    address public invite; //邀请关系合约地址
    address public adr01 = 0x0000000000000000000000000000000000000001;
    uint public inviteReward = 75 ; //奖励百分比
    
    function modifyLGAddr(address newLG_Addr)public ownerOnly{
        LG = newLG_Addr;
    }
    function modifyLGCAddr(address newLGC_Addr)public ownerOnly{
        LGC = newLGC_Addr;
    }
    
    constructor(address _LG, address _LGC, address _invite,address _airdropTotalAdr) public {
        LG = _LG;
        LGC = _LGC;
        invite = _invite;
        airdropTotalAdr = _airdropTotalAdr;
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
    
    function setinvite(address _invite)public ownerOnly{
        invite = _invite;
    }
    
    function setAirdropTotalAdr(address _airdropTotalAdr)public ownerOnly{
        airdropTotalAdr = _airdropTotalAdr;
    }
    
    function inviteReward(uint _inviteReward)public ownerOnly{
        inviteReward = _inviteReward;
    }
    
    //////////////////////////////////////    
    
    //供应每日量
    function addDayamount()public {
        require(_adayamount <= AirdropAmount.mul(4)  && now >= adayTime.add(timeD.mul(1 days)) );
        adayTime = now;
        _adayamount = adayamount;
    }
    
    function getAirdrop(address _inviter) public LGCchack{
        require(IERC20(LG).balanceOf(msg.sender) >= airdropTotal(airdropTotalAdr).getUsertotal(msg.sender));
        require(_inviter != msg.sender);
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
        ///////////以下为邀请机制判断
        address inviter = Invite(invite).getInviter(msg.sender);
        if(inviter == address(0)){  //第一次进入
            Invite(invite).saveInviter(msg.sender,_inviter);
            if(_inviter == adr01){ //自来客
                IERC20(LG).transfer(msg.sender, c);
            }else{//有邀请人
                IERC20(LG).transfer(msg.sender, c);
                if(IERC20(LG).balanceOf(msg.sender) < IERC20(LG).balanceOf(_inviter)){  //如果邀请人帐户LG余额少于被邀请人，将无法获得奖励
                    IERC20(LG).transfer(_inviter, c.mul(inviteReward).div(100));
                }
            }
        }
        if(inviter == adr01){ //自来客
            IERC20(LG).transfer(msg.sender, c);
        }
        if(inviter != address(0) && inviter != adr01){ //有邀请人
            IERC20(LG).transfer(msg.sender, c);
            if(IERC20(LG).balanceOf(msg.sender) < IERC20(LG).balanceOf(inviter)){  //如果邀请人帐户LG余额少于被邀请人，将无法获得奖励
                IERC20(LG).transfer(inviter, c.mul(inviteReward).div(100));
            }
        }
        ///////////以上为邀请机制判断
        airdropTotal(airdropTotalAdr).saveUsertotal(msg.sender,c);
    }
    
    function claim() public ownerOnly{
        uint amount = IERC20(LG).balanceOf(address(this));
        IERC20(LG).transfer(msg.sender, amount);
    }
    
    //用户获取领取剩余时间（秒）
    function userTime() public view returns(uint){
        if(now >= timemap[msg.sender] ){
        uint a=0 ;
        }else{
            a = timemap[msg.sender].sub(now);
        }
        return a;
    }
    
    //获取供应剩余时间（秒）
    function getTime()public view returns(uint){
       if(now >= adayTime.add(timeD.mul(1 days)) ){
        uint a=0 ;
        }else{
            a = adayTime.add(timeD.mul(1 days)).sub(now);
        }
        return a;
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

interface airdropTotal{
    function saveUsertotal(address _user,uint _value) external;
    function getUsertotal(address _user) external view returns(uint);
}
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

contract hongbao{
    using SafeMath for uint;
    

    
    
    struct HBinfo{
        uint id;
        address userAdr;
        string remark;
        address tokenAdr;
        uint total;
        uint amount;
        uint isFee;  //内部用于记录是否已付手续费
        uint _balance; //该红包所剩余额
        uint time;  //发红包的时间
        mapping(address => uint) isgetmap;
    }
    
    
    uint public HBid ;  //红包ID
    mapping(uint => HBinfo) HBmap; //红包信息与ID绑定
    mapping(address => uint) tokenIsPayFee; //该种通证是否可以支付手续费,0为可以，1为不可以，默认为0
    mapping(address => uint) public  feeMap; //记录有多少是LG的收益
    
    
    
    
    //用ID号获取红包信息
    function getHBinfo(uint _HBid)public view returns(uint, address,string,address,uint,uint,uint,uint,uint){
        HBinfo storage _HBinfo = HBmap[_HBid];
        return(
            _HBinfo.id,
            _HBinfo.userAdr,
            _HBinfo.remark,
            _HBinfo.tokenAdr,
            _HBinfo.total,
            _HBinfo.amount,
            _HBinfo._balance,
            _HBinfo.time,
            _HBinfo.isgetmap[msg.sender]
            );
    }
    
    //还需添加消费值记录系统//添加定时红包
    function giveTokenHB(address _tokenAdr, uint _total, uint _amount, string _remark) public payable{
        require(Itoken(_tokenAdr).balanceOf(msg.sender) >= _total && _total >= 10000); //要求发送者拥有足够的TOKEN
        if(tokenIsPayFee[_tokenAdr]==1){require(msg.value==HTforFee);}
        uint _HBid;//用在for循环里
        uint _HBid2;
        //寻找已有的红包ID中有没有空的ID
        for(uint i=1; i<=HBid; i++){
            if(HBmap[i].id == 0){
                _HBid = i;
            }
        }
        
        //如果有就定义_HBid2等于旧的ID，如果没有就定义为新的ID
        if(_HBid !=0){
            _HBid2 = _HBid;
        }else{
            HBid++;
            _HBid2 = HBid;
        }
        
        HBmap[_HBid2] = HBinfo(_HBid2, msg.sender, _remark, _tokenAdr, _total, _amount, 0, _total, now);//存储红包信息
        Itoken(_tokenAdr).transferFrom(msg.sender, address(this), _total);//转帐
        
    }
    
    mapping(address => uint)lastHB;//查询红包结果
    
    //领红包//添加定时红包领取/添加领取条件>=100LG
    function getHB(uint _HBid) public{
        HBinfo storage _HBinfo = HBmap[_HBid];
        require(_HBinfo.isgetmap[msg.sender] != _HBinfo.time);
        uint _fee = _HBinfo.total.mul(fee).div(1000);
        if(_HBinfo.isFee == 0){
            _HBinfo._balance = _HBinfo._balance.sub(_fee);
            feeMap[_HBinfo.tokenAdr] = feeMap[_HBinfo.tokenAdr].add(_fee) ; 
            _HBinfo.isFee = 1;
        }
        _HBinfo.isgetmap[msg.sender] = _HBinfo.time;
        ////////////////////////////////////////////////////////////////////////
        uint suiJiShu;
        uint _suiJiShu;
        suiJiShu = uint (keccak256(abi.encodePacked(now,msg.sender))).mod(10);
        if(suiJiShu == 0 ){_suiJiShu = suiJiShu+1;}
        else{_suiJiShu = suiJiShu;}
        uint a = _HBinfo._balance.div(_HBinfo.amount).mul(2).mul(_suiJiShu).div(10);
        ////////////////////////////////////////////////////////////////////////
        if(_HBinfo.amount > 1 ){
            Itoken(_HBinfo.tokenAdr).transfer(msg.sender, a);
            _HBinfo._balance = _HBinfo._balance.sub(a);
            _HBinfo.amount = _HBinfo.amount - 1;
            uint b = a;
            lastHB[msg.sender] = b;
        }else{
                Itoken(_HBinfo.tokenAdr).transfer(msg.sender, _HBinfo._balance);
                b = _HBinfo._balance;
                delete HBmap[_HBid];
                lastHB[msg.sender] = _HBinfo._balance;
        }
    }
    
    
    
    
    
    ///////////////////////////////////////////////////
    address public ILGgongxianAddr;// 消费值记录系统地址
    address public owner;    //管理员地址 
    uint fee = 20; //平台收益千分比
    uint HTforFee = 1e16; //用HT付手续费
    
    

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
    
    //设置手续费比率
    function setFee(uint _fee) public ownerOnly{
        fee = _fee;
    }
    
    //设置HT手续费
    function setfeeForHT(uint _HTforFee) public ownerOnly{
        HTforFee = _HTforFee;
    }
    
    
    //设置该种通证是否可以支付手续费,0为可以，1为不可以，默认为0
    function setTokenIsPayFee(address _tokenAdr, uint _is) public ownerOnly{
        tokenIsPayFee[_tokenAdr] = _is;
    }
    
    //查看该种通证是否可以支付手续费,0为可以，1为不可以，默认为0
    function getTokenIsPayFee(address _tokenAdr) public view returns(uint){
        return(tokenIsPayFee[_tokenAdr]);
    }
    
     //设置消费值记录系统地址
    function setILGgongxianAddr(address _ILGgongxianAddr) public ownerOnly{
        ILGgongxianAddr = _ILGgongxianAddr;
    }
    
    //管理员提取收益
    function clamToken(address _tokenAdr)public ownerOnly{
        Itoken(_tokenAdr).transfer(msg.sender, feeMap[_tokenAdr]);
        feeMap[_tokenAdr] = 0;
    }

    //////////////////////////////////////////////////
        
}


   //合约接口
interface Itoken{
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function approve(address spender, uint256 value)external returns (bool);
    function transferFrom(address from, address to, uint256 value)external returns (bool);
}

//贡献值记录系统接口
interface ILGgongxian{
    function addGongxianzhi(address _user, uint _value)external;
}
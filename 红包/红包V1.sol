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
        string userName;
        string remark;
        address tokenAdr;
        uint total;
        uint amount;
        uint isFee;  //内部用于记录是否已付手续费
        uint _balance; //该红包所剩余额
        uint lownBalance; //可领最少得有多少该TOKEN余额
        uint password; //密码
        uint time;
        address userAdr;
        mapping(address => uint) isgetmap;
    }
    
    uint public HBid ;  //红包ID
    mapping(uint => HBinfo) HBmap; //红包信息与ID绑定

    mapping(address => uint) public  feeMap; //记录有多少是LG的收益
    mapping(address => string) userName; //用户昵称存储
    mapping(address => uint) public lastHB;//查询红包结果
    mapping(address => address) public lastTokenAdr; //查询红包结果地址
    
    //用户昵称注册
    function changUserName(string _name)public{
        userName[msg.sender] = _name;
    }
    
    //用ID号获取红包信息
    function getHBinfo(uint _HBid)public view returns(uint, string,string,address,uint,uint,uint,uint, uint){
        HBinfo storage _HBinfo = HBmap[_HBid];
        return(
            _HBinfo.id,
            _HBinfo.userName,
            _HBinfo.remark,
            _HBinfo.tokenAdr,
            _HBinfo.total,
            _HBinfo.amount,
            _HBinfo._balance,
            _HBinfo.lownBalance,
            _HBinfo.isgetmap[msg.sender]
            );
    }
    
    //发红包
    function giveTokenHB(address _tokenAdr, uint _total, uint _amount, string _remark, uint _lownBalance,uint _password ) public payable{
        require(Itoken(_tokenAdr).balanceOf(msg.sender) >= _total && _total >= 10000 && Itoken(LGadr).balanceOf(msg.sender) >= lowLG); //要求发送者拥有足够的TOKEN,总量大于1万（防计算溢出）,使用本系统最少持有lowLGLG
        if(tokenIsPayFee[_tokenAdr]==1){require(msg.value==HTforFee); }
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
        HBmap[_HBid2] = HBinfo(_HBid2, userName[msg.sender], _remark, _tokenAdr, _total, _amount, 0, _total,_lownBalance, _password, now, msg.sender);//存储红包信息
        Itoken(_tokenAdr).transferFrom(msg.sender, address(this), _total);//转帐
        
        if(isGetLG[_tokenAdr] ==1 ){
             uint a = _total.mul(fee).div(1000);
             uint b = a.mul(getLGratio).div(100);
             uint c = TokenVsLGratio[_tokenAdr];
             uint GXvalue = b.mul(c).div(100);
            ILGVgongxian(ILGVgongxianAddr).addGongxianzhi(msg.sender,GXvalue);
        }
    }
    
    
    //领红包
    function getHB(uint _HBid, uint _password) public{
        HBinfo storage _HBinfo = HBmap[_HBid];
        require(_HBinfo.isgetmap[msg.sender] != 1 && Itoken(LGadr).balanceOf(msg.sender) >= lowLG );
        require(Itoken(_HBinfo.tokenAdr).balanceOf(msg.sender) >= _HBinfo.lownBalance);
        if(_HBinfo.password != 0 ){
            require( _password == _HBinfo.password);
        }
        uint _fee = _HBinfo.total.mul(fee).div(1000);
        if(_HBinfo.isFee == 0){
            _HBinfo._balance = _HBinfo._balance.sub(_fee);
            feeMap[_HBinfo.tokenAdr] = feeMap[_HBinfo.tokenAdr].add(_fee); 
            _HBinfo.isFee = 1;
        }
        _HBinfo.isgetmap[msg.sender] = 1;
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
            lastTokenAdr[msg.sender] = _HBinfo.tokenAdr;
        }else{
                Itoken(_HBinfo.tokenAdr).transfer(msg.sender, _HBinfo._balance);
                b = _HBinfo._balance;
                lastTokenAdr[msg.sender] = _HBinfo.tokenAdr;
                lastHB[msg.sender] = _HBinfo._balance;
                delete HBmap[_HBid];
        }
       
    }
    
    //48小时后发红包者可领取未领完红包
    function getHBbalance(uint _HBid)public{
        HBinfo storage _HBinfo = HBmap[_HBid];
        require(_HBinfo.userAdr == msg.sender && now >= _HBinfo.time.add(2 days));
        Itoken(_HBinfo.tokenAdr).transfer(msg.sender, _HBinfo._balance);
    }
    
    //发红包者可查询红包密码
    function getHBpassword(uint _HBid)public view returns(uint){
        HBinfo storage _HBinfo = HBmap[_HBid];
        require(_HBinfo.userAdr == msg.sender);
        return(_HBinfo.password);
    }
    
    //发红包者可查询红包条件
    function getHBlownBalance(uint _HBid)public view returns(uint){
        HBinfo storage _HBinfo = HBmap[_HBid];
        require(_HBinfo.userAdr == msg.sender);
        return(_HBinfo.lownBalance);
    }
    
    //发红包者可修改红包留言
    function modifyremark(uint _HBid, string _remark)public{
        HBinfo storage _HBinfo = HBmap[_HBid];
        require(_HBinfo.userAdr == msg.sender);
        _HBinfo.remark = _remark;
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    address public ILGVgongxianAddr; //V贡献值记录系统地址
    address public owner;    //管理员地址 
    uint public fee = 100; //平台收益千分比
    mapping(address => uint) public tokenIsPayFee; //该种通证是否可以支付手续费,0为可以，1为不可以，默认为0
    uint public HTforFee = 1e15; //用HT付手续费
    mapping(address => uint)public isGetLG; //通证是否可以挖矿LG,1为可以，0为不可以，默认0
    uint public lowLG = 100e18; //使用本系统最少持有多少LG
    address public LGadr; //LG通证地址
    uint public getLGratio = 50 ; //挖矿LG比率，默认为50%，
    mapping(address => uint) public TokenVsLGratio; //通证与LG的汇率，如：A比LG贵2倍，即输入200，便宜50%，即输50
    

    constructor(address _LGadr, address _ILGVgongxianAddr) public {
        owner = msg.sender;
        LGadr = _LGadr ;
        ILGVgongxianAddr = _ILGVgongxianAddr;
        
    }
    modifier ownerOnly() {
        require(msg.sender == owner);
        _; 
    }
    
    function transferOwer(address newOwner)public ownerOnly{
        owner = newOwner;
    }
    
    // 1比1 (address, 0, 1, 100)
    //_isPayfee 设置该种通证是否可以支付手续费,0为可以，1为不可以，默认为0
    //_isGetLG 设置该种通证是否可以挖矿,1为可以，0为不可以，默认为0.  
    //_TokenVsLGratio 设置通证与LG的汇率,如：A比LG贵2倍，即输入200，便宜50%，即输50
    // 需要注意，如果该通证不能支付手续费，那也不能挖矿。即key2=0,key3=1, key2=1 key3=0
    function setToken(address _tokenAdr,uint _isPayfee ,uint _isGetLG, uint _TokenVsLGratio) public ownerOnly{
        tokenIsPayFee[_tokenAdr] = _isPayfee;
        isGetLG[_tokenAdr] = _isGetLG; 
        TokenVsLGratio[_tokenAdr] = _TokenVsLGratio;
    }
    
    
    //设置手续费比率
    function setFee(uint _fee) public ownerOnly{
        fee = _fee;
    }
    
    //设置HT手续费
    function setfeeForHT(uint _HTforFee) public ownerOnly{
        HTforFee = _HTforFee;
    }
    
    //设置使用本系统最少持有多少LG
    function setLowLG(uint _lowLG) public ownerOnly{
        lowLG = _lowLG;
    }
    
     //设置消费值记录系统地址
    function setILGgongxianAddr(address _ILGVgongxianAddr) public ownerOnly{
        ILGVgongxianAddr = _ILGVgongxianAddr;
    }
    
    //管理员提取收益
    function clamToken(address _tokenAdr)public ownerOnly{
        Itoken(_tokenAdr).transfer(msg.sender, feeMap[_tokenAdr]);
        feeMap[_tokenAdr] = 0;
    }
    
    //管理员提取HT收益
    function clamHT()public ownerOnly{
        msg.sender.transfer(address(this).balance);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
        
}


   //合约接口
interface Itoken{
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function transferFrom(address from, address to, uint256 value)external returns (bool);
}

//V贡献值记录系统地址
interface ILGVgongxian{
    function addGongxianzhi(address _user, uint _value)external;
}
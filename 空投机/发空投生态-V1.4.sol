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

contract anyAirdrop{
    using SafeMath for uint;
    
    //空投信息
     struct AirToken{
         address tokenAdr;
         uint AirdropAmount;
         address tokenOwner;
         uint a; //空投轮次，用于判定是否已领
         mapping (address => uint) isgetmap;
     }
    //空投信息存储
    mapping(address => AirToken) tokenMap;
    
    
    //发布空投信息
    function giveAirdrop(address _tokenAdr,uint _AirdropAmount , uint _AirdropTotal) public{
        require(tokenMap[_tokenAdr].tokenAdr == 0x0 && Itoken(_tokenAdr).balanceOf(msg.sender) >= _AirdropTotal);
        uint _a = (tokenMap[_tokenAdr].a) +1;
        tokenMap[_tokenAdr] = AirToken(_tokenAdr, _AirdropAmount, msg.sender, _a );
        if(isSaveGX==1){ILGgongxian(ILGgongxianAddr).addGongxianzhi(msg.sender,GXgiveAirdrop);}
        
        if(isfeetoken==1){Itoken(_tokenAdr).transferFrom(msg.sender,address(this),_AirdropTotal.sub(_AirdropTotal.mul(feeToken).div(1000)));
            Itoken(_tokenAdr).transferFrom(msg.sender,owner,_AirdropTotal.mul(feeToken).div(1000));
        }
        else{Itoken(_tokenAdr).transferFrom(msg.sender,address(this),_AirdropTotal);}
    }

    //领取空投
    function getAirdrop(address _tokenAdr) public{
        AirToken storage _Airtoken1 = tokenMap[_tokenAdr];
        require(_Airtoken1.isgetmap[msg.sender] != tokenMap[_tokenAdr].a  && Itoken(LGC).balanceOf(msg.sender) >= LGCrequirement );
        _Airtoken1.isgetmap[msg.sender] = _Airtoken1.a ;
        if(Itoken(_Airtoken1.tokenAdr).balanceOf(address(this)) >= _Airtoken1.AirdropAmount)
            {
            Itoken(_Airtoken1.tokenAdr).transfer(msg.sender, _Airtoken1.AirdropAmount);
            }
        else{
            Itoken(_Airtoken1.tokenAdr).transfer(msg.sender, Itoken(_Airtoken1.tokenAdr).balanceOf(address(this)));
        }
        if(isSaveGX==1){ILGgongxian(ILGgongxianAddr).addGongxianzhi(msg.sender,GXgetAirdrop);}
    }
    
    //空投发布人可提出未领完的通证
    function claim(address _tokenAdr) public{
        AirToken storage _Airtoken1 = tokenMap[_tokenAdr];
        require(_Airtoken1.tokenOwner == msg.sender);
        uint amount = Itoken(_Airtoken1.tokenAdr).balanceOf(address(this));
        Itoken(_Airtoken1.tokenAdr).transfer(msg.sender, amount);
        tokenMap[_tokenAdr]= AirToken(address(0), 0, address(0),tokenMap[_tokenAdr].a );
    }
    
    //空投发布人可修改单个空投量
    function modifyAirdropAmount(address _tokenAdr, uint _AirdropAmount) public{
        AirToken storage _Airtoken1 = tokenMap[_tokenAdr];
        require(_Airtoken1.tokenOwner == msg.sender);
        _Airtoken1.AirdropAmount = _AirdropAmount;
    }
    
    // 空投发布人转移权限
    function transferTokenOwner(address _tokenAdr, address _tokenOwner)public{
        AirToken storage _Airtoken1 = tokenMap[_tokenAdr];
        require(_Airtoken1.tokenOwner == msg.sender);
        _Airtoken1.tokenOwner = _tokenOwner;
    }
    
    //获取空投信息
    function getAirTokenInfo(address _tokenAdr) public view returns(address,uint,address,uint){
        AirToken storage _Airtoken1 = tokenMap[_tokenAdr];
        return (_Airtoken1.tokenAdr, _Airtoken1.AirdropAmount, _Airtoken1.tokenOwner ,_Airtoken1.a );
    }
    
/////////////////////////////////////////////////////////////
    uint public GXgetAirdrop = 1;//领空投贡献值
    uint public GXgiveAirdrop = 10;//发空投贡献值
    uint public GXbuy = 20;
    address public owner;    //管理员地址 
    address public ILGgongxianAddr;//贡献值记录系统地址
    uint public isSaveGX = 0; //是否计算贡献值,1=yes,0=no
    uint public isfeetoken = 0; //是否收取空投手续费
    uint public feeToken = 5; //空投手续费千分比
    uint public fee = 2e17;  //30天的费用
    address public LGC;
    uint public LGCrequirement = 10 ;
    
    constructor(address _IGXaddr,address _LGC) public {
        LGC = _LGC;
        owner = msg.sender;
        ILGgongxianAddr = _IGXaddr;
    }
    modifier ownerOnly() {
        require(msg.sender == owner);
        _; 
    }
    function transferOwer(address newOwner)public ownerOnly{
        owner = newOwner;
    }
    
    function modifyLGCAddr(address newLGC_Addr)public ownerOnly{
        LGC = newLGC_Addr;
    }
    
    function modifyLGCrequirement(uint _LGCrequirement)public ownerOnly{
        LGCrequirement = _LGCrequirement;
    }

    //管理员修改领空投贡献值
    function modifyGXgetAirdrop(uint _value) public ownerOnly{
        GXgetAirdrop = _value;
    }
    //管理员修改发空投贡献值
    function modifyGXgiveAirdrop(uint _value) public ownerOnly{
        GXgiveAirdrop = _value;
    }
    //管理员修改买展示位贡献值
    function modifyGXbuy(uint _value) public ownerOnly{
        GXbuy = _value;
    }
    //管理员修改贡献值记录系统地址
    function modifyILGgongxianAddr(address _addr) public ownerOnly{
        ILGgongxianAddr = _addr;
    }
    //管理员设定7天的费用
    function setFee(uint _fee) public ownerOnly{
        fee = _fee;
    }
    //管理员设定空投手续费千分比
    function setfeeToken(uint _feeToken) public ownerOnly{
        feeToken = _feeToken;
    }
    //管理员设定是否计算贡献值,1=yes,0=no
    function setisSaveGX(uint _yesORno) public ownerOnly{
        isSaveGX = _yesORno;
    }
    //管理员设定是否收取空投手续费,1=yes,0=no
    function setisfeetoken(uint _yesORno) public ownerOnly{
        isfeetoken = _yesORno;
    }
    
    //管理员可以领取合约里的HT，即用户付的费用。不可以领token
    function getHT()public ownerOnly{
        address thisaddr = this;
        msg.sender.transfer(thisaddr.balance);
    }
    
//////////////////////////////////////////////////////////////
    
    //展示区信息存储
    struct Ex{
        address Exaddr;
        uint time;
        string remarks;
    }
    
    //展示区信息映射
    mapping (uint => Ex) ExidMap;
    
    //系统调用显示展示区信息
    function getAddrByExid(uint _id)public view returns(address, uint, string){
        require( now <= ExidMap[_id].time);
        return(ExidMap[_id].Exaddr,ExidMap[_id].time, ExidMap[_id].remarks);
    }
    
    //购买展示区空位，（输入展示位编号、要展示的通证地址、购买几周）
    function buy(uint _id,address _tokenAdr, uint _weeks,string _remarks) payable public{
        require(msg.value >= fee.mul(_weeks) && now > ExidMap[_id].time);
        uint _time = now .add(_weeks.mul(7 days));
        ExidMap[_id] = Ex(_tokenAdr, _time, _remarks);
        if(isSaveGX==1){ILGgongxian(ILGgongxianAddr).addGongxianzhi(msg.sender,GXbuy);}
    }
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
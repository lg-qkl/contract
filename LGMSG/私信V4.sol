pragma solidity = 0.5.17;
pragma experimental ABIEncoderV2;

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

contract LGmessage {
    using SafeMath for uint;
    
    struct message{
        address _sender;
        address To;
        string msgcontent;
    }
    
    uint public msgID;  //信息ID
    mapping(uint=>message) msgMap; //信息ID与内容绑定
    mapping(address=>uint[]) userInbox; //用户收件箱
    mapping(address=>uint[]) userOutbox; //用户发件箱
    mapping(address=>uint)public userTime; //用户付费时限
    mapping(address=>uint8)public freeTimesMap;  //用户免费发送条数
 
    //发送信息
    function sendMsg(address to, string memory _message)public{
        if(freeTimesMap[msg.sender] >= freeCount){
            require(userTime[msg.sender] >= now);
        }else{
            freeTimesMap[msg.sender] = freeTimesMap[msg.sender] + 1 ;
        }
        msgID ++; 
        message memory newMessage = message({
                    _sender: msg.sender,
                    To: to,
                    msgcontent: _message
                });
        msgMap[msgID] = newMessage;
        userInbox[to].push(msgID);
        userOutbox[msg.sender].push(msgID);
    }

    //购买时效
    function buy(uint _days)public {
        require(_days >= 30);
        if(userTime[msg.sender] <= now){
            userTime[msg.sender] = now.add(_days.mul(86400));
        }else{
            userTime[msg.sender] = userTime[msg.sender] .add(_days.mul(86400));
        }
        uint  feeAll = feeLG().mul(_days.sub( (_days.sub(30)).mul(discount).div(100) ) );
        IERC20(LG).transferFrom(msg.sender, address(this),feeAll);
        address  invite = Invite(InviteAdr).getInviter(msg.sender);
        if(invite != zeroAdr1 && invite != zeroAdr1 && IERC20(LG).balanceOf(msg.sender)<IERC20(LG).balanceOf(invite) ){
            IERC20(LG).transfer(invite, feeAll.mul(inviteFee).div(100));
        }
    }
    ///////////////////////计价模组//////////////////////////////////
    uint public fee = 50;  //每日费用RMB,单位分
    //计算费用LG的个数
    function feeLG()public view returns(uint){
      uint LGprice= Price(HQadr).PriceByAdr(LG);
      uint LGamout = (fee*1e34).div(LGprice);
      return LGamout;
    }
    //费用设定
    function setFee(uint _fee)public ownerOnly{
        fee= _fee;
    }
    
    //////////////////////////管理员模组/////////////////////////
    address public owner; 
    uint8 public freeCount = 5; //免费条数
    uint8 public inviteFee=30; //邀请员提成 30%
    uint8 public discount = 20 ; //购买每增加一天的打折率。 20表示0.2%
    modifier ownerOnly() {
        require(msg.sender == owner);
        _; 
    }
    function transferOwer(address newOwner)public ownerOnly{
        owner = newOwner;
    }
    //提取费用
    function clamLG()public ownerOnly{
        IERC20(LG).transfer(
            msg.sender,
            IERC20(LG).balanceOf(address(this))
            );
    }
    //邀请员提成 输入30= 30%
    function setInviteFee(uint8 _fee)public ownerOnly{
        inviteFee = _fee; 
    }
    //购买每增加一天的打折率。 20表示0.2%
    function setDiscount(uint8 _fee)public ownerOnly{
        discount = _fee; 
    }

    //免费条数 5表示5条
    function setFreeCount(uint8 _fee)public ownerOnly{
        freeCount = _fee; 
    }
    ///////////////////////部署模组/////////////////////////////
    address public HQadr ; //行情地址
    address  LG  ; //LG通证地址
    address public InviteAdr; //邀请关系合约地址
    address zeroAdr1 = 0x0000000000000000000000000000000000000001;
    address zeroAdr0 = 0x0000000000000000000000000000000000000000;
    constructor(address LGadr,address _HQadr, address _inviteAdr) public {
        owner = msg.sender;
        LG = LGadr;
        HQadr= _HQadr;
        InviteAdr = _inviteAdr;
    }
    //修改LG地址
    function iLG(address adr)public ownerOnly{
        LG= adr;
    }
    //修改行情地址
    function setHQadr(address _HQadr)public ownerOnly{
        HQadr= _HQadr;
    }
    //修改邀请关系合约地址
    function setInviteAdr(address _inviteAdr)public ownerOnly{
        InviteAdr = _inviteAdr;
    }
    ///////////////////////////////////////////////////////////

 
    //获取发件箱
    function outbox()public view returns(address[]memory, string[] memory){
        uint[] memory _id = userOutbox[msg.sender];
        address[] memory to = new address[](_id.length);
        string[] memory _msg = new string[](_id.length);
        for(uint i=0;i<_id.length;i++){
            to[i] = msgMap[_id[i]].To;
            _msg[i] = msgMap[_id[i]].msgcontent;
        }
        return (to,_msg);
    }

    //发件箱数量
    function outboxCount()public view returns(uint){
        return userOutbox[msg.sender].length;
    }

    //获取收件箱
    function inbox()public view returns(address[]memory, string[] memory){
        uint[] memory _id = userInbox[msg.sender];
        address[] memory sender = new address[](_id.length);
        string[] memory _msg = new string[](_id.length);
        for(uint i=0;i<_id.length;i++){
            sender[i] = msgMap[_id[i]]._sender;
            _msg[i] = msgMap[_id[i]].msgcontent;
        }
        return (sender,_msg);
    }

    //收件箱数量
    function inboxCount()public view returns(uint){
        return userInbox[msg.sender].length;
    }

}

//合约接口
interface IERC20{
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value)external returns (bool);
}
//行情接口
interface Price{
    function getHTprice()external pure returns(uint);
    function PriceByAdr(address _x)external view returns(uint);
}
//邀请关系接口
interface Invite{
    function getInviter(address _user) external view returns(address);
}
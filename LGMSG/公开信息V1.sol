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

contract LGOutmsg {
    using SafeMath for uint;
    
    struct message{
        address _sender;
        string msgcontent;
    }
    
    uint msgID;  //信息ID
    mapping(uint=>message) msgMap; //信息ID与内容绑定
    mapping (address => string) userName;  //呢称
    //改呢称
    function setName(string memory _name)public{
        userName[msg.sender] = _name;
    }
    //获取呢称
    function getName()public view returns(string memory){
        return userName[msg.sender];
    }
    
    //发送信息
    function sendMsg(string memory _message)public{
        msgID ++;
        message memory newMessage = message({
                    _sender: msg.sender,
                    msgcontent: _message
                });
        msgMap[msgID] = newMessage;
        if(fee != 0){
            IERC20(LG).transferFrom(msg.sender, address(this), feeLG());
        }
    }
    //获取全部信息
    function getMsg()public view returns(string[] memory){
        string[] memory _msg = new string[](msgID);
        for(uint i=msgID;i>0;i--){
            _msg[i] = msgMap[i].msgcontent;
        }
        return _msg;
    }
    ///////////////////////计价模组//////////////////////////////////
    uint public fee = 10;  //费用RMB,单位角
    //计算费用LG的个数
    function feeLG()public view returns(uint){
      uint LGprice= price(HQadr).PriceByAdr(LG);
      uint LGamout = (fee*1e35).div(LGprice);
      return LGamout;
    }
    //费用设定
    function setFee(uint _fee)public ownerOnly{
        fee= _fee;
    }
    
    //////////////////////////管理员模组/////////////////////////
    address public owner;
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

    ///////////////////////部署模组/////////////////////////////
    address public HQadr ; //行情地址
    address public LG  ; //LG通证地址
    constructor(address LGadr,address _HQadr) public {
        owner = msg.sender;
        LG = LGadr;
        HQadr= _HQadr;
    }
    //修改LG地址
    function iLG(address adr)public ownerOnly{
        LG= adr;
    }
    //修改行情地址
    function setHQadr(address _HQadr)public ownerOnly{
        HQadr= _HQadr;
    }
    ///////////////////////////////////////////////////////////

}

//合约接口
interface IERC20{
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function transferFrom(address from, address to, uint256 value)external returns (bool);
}

//行情接口
interface price{
    function getHTprice()external pure returns(uint);
    function PriceByAdr(address _x)external view returns(uint);
}
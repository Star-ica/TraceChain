const CHAIN={id:677,hex:"0x2A5",name:"BOT Chain ",symbol:"BOT",rpc:"https://rpc.botchain.ai",explorer:"https://scan.botchain.ai",website:"https://botchain.ai"};
// TODO: replace with your deployed TraceChain address
const CONTRACT_ADDRESS="0x341e61d2a00281f0379336170570de80be687211";
const ABI=["function admin() view returns (address)","function participants(address) view returns (string name,string role,bool active)","function addParticipant(address a,string name,string role)","function removeParticipant(address a)","function participantCount() view returns (uint256)","function participantAt(uint256 i) view returns (address,string,string,bool)","function registerProduct(string name,string batch,string origin) returns (uint256)","function addUpdate(uint256 id,string location,string status,string note)","function transferCustody(uint256 id,address to,string location,string status,string note)","function markDelivered(uint256 id,string location,string note)","function productCount() view returns (uint256)","function getProduct(uint256 id) view returns (string,string,string,address,address,uint256,bool)","function stepCount(uint256 id) view returns (uint256)","function getStep(uint256 id,uint256 i) view returns (address,string,string,string,uint256)","function productsOf(address a) view returns (uint256[])"];
let signer,account,vault;
const ro=/^0x0+$/.test(CONTRACT_ADDRESS)?null:new ethers.Contract(CONTRACT_ADDRESS,ABI,new ethers.JsonRpcProvider(CHAIN.rpc));
const $=s=>document.querySelector(s);
const short=a=>a.slice(0,6)+"…"+a.slice(-4);
const when=t=>new Date(Number(t)*1000).toLocaleString();
const esc=s=>String(s).replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
let tt;function toast(m,err){const t=$("#toast");t.className=err?"err":"";t.innerHTML=m;t.style.display="block";clearTimeout(tt);tt=setTimeout(()=>t.style.display="none",err?6000:5000)}
async function ensureChain(){
  try{await ethereum.request({method:"wallet_switchEthereumChain",params:[{chainId:CHAIN.hex}]})}
  catch(e){if(e.code!==4902&&e.code!==-32603)throw e;
    await ethereum.request({method:"wallet_addEthereumChain",params:[{chainId:CHAIN.hex,chainName:CHAIN.name,nativeCurrency:{name:"BOT",symbol:CHAIN.symbol,decimals:18},rpcUrls:[CHAIN.rpc],blockExplorerUrls:[CHAIN.explorer]}]})}
}
async function connect(){
  if(!window.ethereum)return toast("Install MetaMask or another EVM wallet.",1);
  try{
    await ensureChain();
    const p=new ethers.BrowserProvider(ethereum);await p.send("eth_requestAccounts",[]);
    signer=await p.getSigner();account=await signer.getAddress();$("#wbtn").textContent=short(account);
    if(/^0x0+$/.test(CONTRACT_ADDRESS))return toast("Set CONTRACT_ADDRESS in js/app.js",1);
    vault=new ethers.Contract(CONTRACT_ADDRESS,ABI,signer);
    document.dispatchEvent(new Event("ready"));
  }catch(e){toast(e.shortMessage||e.message,1)}
}
async function tx(p,msg){
  try{const t=await p;toast("Transaction sent… waiting for confirmation");await t.wait();
    toast(msg+' ✓ <a target="_blank" href="'+CHAIN.explorer+'/tx/'+t.hash+'">View on explorer</a>');return true}
  catch(e){toast(e.reason||e.shortMessage||e.message,1);return false}
}
function needWallet(el){el.innerHTML='<div class="notice">Connect your wallet to continue.</div>'}
addEventListener("load",()=>{$("#wbtn").onclick=connect;
  if(window.ethereum)ethereum.request({method:"eth_accounts"}).then(a=>a.length&&connect())});

const _n={};async function nameOf(a){if(!ro)return short(a);if(!_n[a]){const p=await ro.participants(a);_n[a]=p[0]?p[0]+" ("+p[1]+")":short(a)}return _n[a]}

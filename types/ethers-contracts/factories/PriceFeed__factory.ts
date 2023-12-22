/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Signer,
  utils,
  Contract,
  ContractFactory,
  BigNumberish,
  Overrides,
} from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PriceFeed, PriceFeedInterface } from "../PriceFeed";

const _abi = [
  {
    type: "constructor",
    inputs: [
      {
        name: "_base",
        type: "address",
        internalType: "address",
      },
      {
        name: "_quote",
        type: "address",
        internalType: "address",
      },
      {
        name: "_decimals",
        type: "uint8",
        internalType: "uint8",
      },
      {
        name: "_baseStalePrice",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_quoteStalePrice",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "base",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "contract AggregatorV3Interface",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "baseDecimals",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint8",
        internalType: "uint8",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "baseStalePrice",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "decimals",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint8",
        internalType: "uint8",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getPrice",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "quote",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "contract AggregatorV3Interface",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "quoteDecimals",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint8",
        internalType: "uint8",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "quoteStalePrice",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "error",
    name: "INVALID_DECIMALS",
    inputs: [
      {
        name: "decimals",
        type: "uint8",
        internalType: "uint8",
      },
    ],
  },
  {
    type: "error",
    name: "INVALID_PRICE",
    inputs: [
      {
        name: "aggregator",
        type: "address",
        internalType: "address",
      },
      {
        name: "price",
        type: "int256",
        internalType: "int256",
      },
    ],
  },
  {
    type: "error",
    name: "NULL_ADDRESS",
    inputs: [],
  },
  {
    type: "error",
    name: "NULL_STALE_PRICE",
    inputs: [],
  },
  {
    type: "error",
    name: "STALE_PRICE",
    inputs: [
      {
        name: "aggregator",
        type: "address",
        internalType: "address",
      },
      {
        name: "updatedAt",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
] as const;

const _bytecode =
  "0x61016060405234801561001157600080fd5b50604051610a2f380380610a2f83398101604081905261003091610206565b6001600160a01b038516158061004d57506001600160a01b038416155b1561006b5760405163de0ce17d60e01b815260040160405180910390fd5b60ff8316158061007e575060128360ff16115b156100a55760405163b094f61d60e01b815260ff8416600482015260240160405180910390fd5b8115806100b0575080155b156100ce576040516373f9226b60e11b815260040160405180910390fd5b6001600160a01b03808616608081905290851660a05260ff841660c0526101208390526101408290526040805163313ce56760e01b8152905163313ce567916004808201926020929091908290030181865afa158015610132573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610156919061025c565b60ff1660e08160ff168152505060a0516001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa1580156101a3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101c7919061025c565b60ff16610100525061027e9350505050565b80516001600160a01b03811681146101f057600080fd5b919050565b805160ff811681146101f057600080fd5b600080600080600060a0868803121561021e57600080fd5b610227866101d9565b9450610235602087016101d9565b9350610243604087016101f5565b6060870151608090970151959894975095949392505050565b60006020828403121561026e57600080fd5b610277826101f5565b9392505050565b60805160a05160c05160e0516101005161012051610140516107306102ff6000396000818161015d01526102830152600081816101c1015261020e0152600060f70152600060d001526000818160920152818161023701526103fb01526000818161019a015261026201526000818161011e01526101ed01526107306000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c80638e6d2bd01161005b5780638e6d2bd01461015857806398d5fdca1461018d578063999b93af14610195578063a4e413e4146101bc57600080fd5b8063313ce5671461008d57806333f76178146100cb5780633fd1e2bd146100f25780635001f3b514610119575b600080fd5b6100b47f000000000000000000000000000000000000000000000000000000000000000081565b60405160ff90911681526020015b60405180910390f35b6100b47f000000000000000000000000000000000000000000000000000000000000000081565b6100b47f000000000000000000000000000000000000000000000000000000000000000081565b6101407f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b0390911681526020016100c2565b61017f7f000000000000000000000000000000000000000000000000000000000000000081565b6040519081526020016100c2565b61017f6101e3565b6101407f000000000000000000000000000000000000000000000000000000000000000081565b61017f7f000000000000000000000000000000000000000000000000000000000000000081565b60006102ac6102327f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000006102b1565b61025d7f0000000000000000000000000000000000000000000000000000000000000000600a6105b5565b6102a77f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000006102b1565b61042a565b905090565b6000806000846001600160a01b031663feaf968c6040518163ffffffff1660e01b815260040160a060405180830381865afa1580156102f4573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061031891906105e3565b509350509250506000821361035757604051633e8ca01160e21b81526001600160a01b0386166004820152602481018390526044015b60405180910390fd5b836103628242610633565b111561039357604051632c4f4f3160e21b81526001600160a01b03861660048201526024810182905260440161034e565b61041f82866001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa1580156103d5573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103f99190610646565b7f0000000000000000000000000000000000000000000000000000000000000000610448565b925050505b92915050565b600082600019048411830215820261044157600080fd5b5091020490565b60008160ff168360ff161015610481576104628383610669565b6104709060ff16600a610682565b61047a908561068e565b90506104b4565b8160ff168360ff1611156104b1576104998284610669565b6104a79060ff16600a610682565b61047a90856106be565b50825b9392505050565b634e487b7160e01b600052601160045260246000fd5b600181815b8085111561050c5781600019048211156104f2576104f26104bb565b808516156104ff57918102915b93841c93908002906104d6565b509250929050565b60008261052357506001610424565b8161053057506000610424565b816001811461054657600281146105505761056c565b6001915050610424565b60ff841115610561576105616104bb565b50506001821b610424565b5060208310610133831016604e8410600b841016171561058f575081810a610424565b61059983836104d1565b80600019048211156105ad576105ad6104bb565b029392505050565b60006104b460ff841683610514565b805169ffffffffffffffffffff811681146105de57600080fd5b919050565b600080600080600060a086880312156105fb57600080fd5b610604866105c4565b9450602086015193506040860151925060608601519150610627608087016105c4565b90509295509295909350565b81810381811115610424576104246104bb565b60006020828403121561065857600080fd5b815160ff811681146104b457600080fd5b60ff8281168282160390811115610424576104246104bb565b60006104b48383610514565b80820260008212600160ff1b841416156106aa576106aa6104bb565b8181058314821517610424576104246104bb565b6000826106db57634e487b7160e01b600052601260045260246000fd5b600160ff1b8214600019841416156106f5576106f56104bb565b50059056fea2646970667358221220bf27d5bcb2991bc621dac16b8edd1181fda942328dcaddbc04f9835dcc24cfd364736f6c63430008140033";

type PriceFeedConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: PriceFeedConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class PriceFeed__factory extends ContractFactory {
  constructor(...args: PriceFeedConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    _base: string,
    _quote: string,
    _decimals: BigNumberish,
    _baseStalePrice: BigNumberish,
    _quoteStalePrice: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<PriceFeed> {
    return super.deploy(
      _base,
      _quote,
      _decimals,
      _baseStalePrice,
      _quoteStalePrice,
      overrides || {}
    ) as Promise<PriceFeed>;
  }
  override getDeployTransaction(
    _base: string,
    _quote: string,
    _decimals: BigNumberish,
    _baseStalePrice: BigNumberish,
    _quoteStalePrice: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): TransactionRequest {
    return super.getDeployTransaction(
      _base,
      _quote,
      _decimals,
      _baseStalePrice,
      _quoteStalePrice,
      overrides || {}
    );
  }
  override attach(address: string): PriceFeed {
    return super.attach(address) as PriceFeed;
  }
  override connect(signer: Signer): PriceFeed__factory {
    return super.connect(signer) as PriceFeed__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): PriceFeedInterface {
    return new utils.Interface(_abi) as PriceFeedInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): PriceFeed {
    return new Contract(address, _abi, signerOrProvider) as PriceFeed;
  }
}

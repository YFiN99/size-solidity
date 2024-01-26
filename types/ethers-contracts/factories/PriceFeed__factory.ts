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
  "0x61016060405234801561001157600080fd5b50604051610a4c380380610a4c83398101604081905261003091610206565b6001600160a01b038516158061004d57506001600160a01b038416155b1561006b5760405163de0ce17d60e01b815260040160405180910390fd5b60ff8316158061007e575060128360ff16115b156100a55760405163b094f61d60e01b815260ff8416600482015260240160405180910390fd5b8115806100b0575080155b156100ce576040516373f9226b60e11b815260040160405180910390fd5b6001600160a01b03808616608081905290851660a05260ff841660c0526101208390526101408290526040805163313ce56760e01b8152905163313ce567916004808201926020929091908290030181865afa158015610132573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610156919061025c565b60ff1660e08160ff168152505060a0516001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa1580156101a3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101c7919061025c565b60ff16610100525061027e9350505050565b80516001600160a01b03811681146101f057600080fd5b919050565b805160ff811681146101f057600080fd5b600080600080600060a0868803121561021e57600080fd5b610227866101d9565b9450610235602087016101d9565b9350610243604087016101f5565b6060870151608090970151959894975095949392505050565b60006020828403121561026e57600080fd5b610277826101f5565b9392505050565b60805160a05160c05160e05161010051610120516101405161074d6102ff6000396000818161015d01526102830152600081816101c1015261020e0152600060f70152600060d001526000818160920152818161023701526103fb01526000818161019a015261026201526000818161011e01526101ed015261074d6000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c80638e6d2bd01161005b5780638e6d2bd01461015857806398d5fdca1461018d578063999b93af14610195578063a4e413e4146101bc57600080fd5b8063313ce5671461008d57806333f76178146100cb5780633fd1e2bd146100f25780635001f3b514610119575b600080fd5b6100b47f000000000000000000000000000000000000000000000000000000000000000081565b60405160ff90911681526020015b60405180910390f35b6100b47f000000000000000000000000000000000000000000000000000000000000000081565b6100b47f000000000000000000000000000000000000000000000000000000000000000081565b6101407f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b0390911681526020016100c2565b61017f7f000000000000000000000000000000000000000000000000000000000000000081565b6040519081526020016100c2565b61017f6101e3565b6101407f000000000000000000000000000000000000000000000000000000000000000081565b61017f7f000000000000000000000000000000000000000000000000000000000000000081565b60006102ac6102327f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000006102b1565b61025d7f0000000000000000000000000000000000000000000000000000000000000000600a6105d2565b6102a77f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000006102b1565b61042a565b905090565b6000806000846001600160a01b031663feaf968c6040518163ffffffff1660e01b815260040160a060405180830381865afa1580156102f4573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103189190610600565b509350509250506000821361035757604051633e8ca01160e21b81526001600160a01b0386166004820152602481018390526044015b60405180910390fd5b836103628242610650565b111561039357604051632c4f4f3160e21b81526001600160a01b03861660048201526024810182905260440161034e565b61041f82866001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa1580156103d5573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103f99190610663565b7f0000000000000000000000000000000000000000000000000000000000000000610441565b925050505b92915050565b60006104378484846104b1565b90505b9392505050565b60008160ff168360ff16101561047a5761045b8383610686565b6104699060ff16600a61069f565b61047390856106ab565b905061043a565b8160ff168360ff1611156104aa576104928284610686565b6104a09060ff16600a61069f565b61047390856106db565b508261043a565b60008260001904841183021582026104d15763ad251c276000526004601cfd5b5091020490565b634e487b7160e01b600052601160045260246000fd5b600181815b8085111561052957816000190482111561050f5761050f6104d8565b8085161561051c57918102915b93841c93908002906104f3565b509250929050565b60008261054057506001610424565b8161054d57506000610424565b8160018114610563576002811461056d57610589565b6001915050610424565b60ff84111561057e5761057e6104d8565b50506001821b610424565b5060208310610133831016604e8410600b84101617156105ac575081810a610424565b6105b683836104ee565b80600019048211156105ca576105ca6104d8565b029392505050565b600061043a60ff841683610531565b805169ffffffffffffffffffff811681146105fb57600080fd5b919050565b600080600080600060a0868803121561061857600080fd5b610621866105e1565b9450602086015193506040860151925060608601519150610644608087016105e1565b90509295509295909350565b81810381811115610424576104246104d8565b60006020828403121561067557600080fd5b815160ff8116811461043a57600080fd5b60ff8281168282160390811115610424576104246104d8565b600061043a8383610531565b80820260008212600160ff1b841416156106c7576106c76104d8565b8181058314821517610424576104246104d8565b6000826106f857634e487b7160e01b600052601260045260246000fd5b600160ff1b821460001984141615610712576107126104d8565b50059056fea264697066735822122061d48f855fbeb09197aa18b95f5112628495a0b9168b1a1e0f8fd9f280c6769764736f6c63430008140033";

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

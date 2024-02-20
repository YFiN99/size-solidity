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
        name: "_baseStalePriceInterval",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_quoteStalePriceInterval",
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
    name: "baseStalePriceInterval",
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
    name: "quoteStalePriceInterval",
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
  {
    type: "error",
    name: "SafeCastOverflowedIntToUint",
    inputs: [
      {
        name: "value",
        type: "int256",
        internalType: "int256",
      },
    ],
  },
  {
    type: "error",
    name: "SafeCastOverflowedUintToInt",
    inputs: [
      {
        name: "value",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
] as const;

const _bytecode =
  "0x61016060405234801561001157600080fd5b50604051610aac380380610aac83398101604081905261003091610206565b6001600160a01b038516158061004d57506001600160a01b038416155b1561006b5760405163de0ce17d60e01b815260040160405180910390fd5b60ff8316158061007e575060128360ff16115b156100a55760405163b094f61d60e01b815260ff8416600482015260240160405180910390fd5b8115806100b0575080155b156100ce576040516373f9226b60e11b815260040160405180910390fd5b6001600160a01b03808616608081905290851660a05260ff841660c0526101208390526101408290526040805163313ce56760e01b8152905163313ce567916004808201926020929091908290030181865afa158015610132573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610156919061025c565b60ff1660e08160ff168152505060a0516001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa1580156101a3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101c7919061025c565b60ff16610100525061027e9350505050565b80516001600160a01b03811681146101f057600080fd5b919050565b805160ff811681146101f057600080fd5b600080600080600060a0868803121561021e57600080fd5b610227866101d9565b9450610235602087016101d9565b9350610243604087016101f5565b6060870151608090970151959894975095949392505050565b60006020828403121561026e57600080fd5b610277826101f5565b9392505050565b60805160a05160c05160e0516101005161012051610140516107ac610300600039600081816101c101526102830152600081816092015261020e0152600061012c0152600061010501526000818160cc0152818161023701526103fb01526000818161019a015261026201526000818161015301526101ed01526107ac6000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c80635001f3b51161005b5780635001f3b51461014e57806398d5fdca1461018d578063999b93af14610195578063ce52a6b4146101bc57600080fd5b80630b0842491461008d578063313ce567146100c757806333f76178146101005780633fd1e2bd14610127575b600080fd5b6100b47f000000000000000000000000000000000000000000000000000000000000000081565b6040519081526020015b60405180910390f35b6100ee7f000000000000000000000000000000000000000000000000000000000000000081565b60405160ff90911681526020016100be565b6100ee7f000000000000000000000000000000000000000000000000000000000000000081565b6100ee7f000000000000000000000000000000000000000000000000000000000000000081565b6101757f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b0390911681526020016100be565b6100b46101e3565b6101757f000000000000000000000000000000000000000000000000000000000000000081565b6100b47f000000000000000000000000000000000000000000000000000000000000000081565b60006102ac6102327f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000006102b1565b61025d7f0000000000000000000000000000000000000000000000000000000000000000600a610631565b6102a77f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000006102b1565b610435565b905090565b6000806000846001600160a01b031663feaf968c6040518163ffffffff1660e01b815260040160a060405180830381865afa1580156102f4573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610318919061065f565b509350509250506000821361035757604051633e8ca01160e21b81526001600160a01b0386166004820152602481018390526044015b60405180910390fd5b8361036282426106af565b111561039357604051632c4f4f3160e21b81526001600160a01b03861660048201526024810182905260440161034e565b61041f82866001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa1580156103d5573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103f991906106c2565b7f000000000000000000000000000000000000000000000000000000000000000061044c565b915061042a826104b9565b925050505b92915050565b60006104428484846104e3565b90505b9392505050565b60008160ff168360ff16101561048d5761047c61046984846106e5565b6104779060ff16600a6106fe565b61050a565b610486908561070a565b9050610445565b8160ff168360ff1611156104b2576104a861046983856106e5565b610486908561073a565b5082610445565b6000808212156104df57604051635467221960e11b81526004810183905260240161034e565b5090565b60008260001904841183021582026105035763ad251c276000526004601cfd5b5091020490565b60006001600160ff1b038211156104df5760405163123baf0360e11b81526004810183905260240161034e565b634e487b7160e01b600052601160045260246000fd5b600181815b8085111561058857816000190482111561056e5761056e610537565b8085161561057b57918102915b93841c9390800290610552565b509250929050565b60008261059f5750600161042f565b816105ac5750600061042f565b81600181146105c257600281146105cc576105e8565b600191505061042f565b60ff8411156105dd576105dd610537565b50506001821b61042f565b5060208310610133831016604e8410600b841016171561060b575081810a61042f565b610615838361054d565b806000190482111561062957610629610537565b029392505050565b600061044560ff841683610590565b805169ffffffffffffffffffff8116811461065a57600080fd5b919050565b600080600080600060a0868803121561067757600080fd5b61068086610640565b94506020860151935060408601519250606086015191506106a360808701610640565b90509295509295909350565b8181038181111561042f5761042f610537565b6000602082840312156106d457600080fd5b815160ff8116811461044557600080fd5b60ff828116828216039081111561042f5761042f610537565b60006104458383610590565b80820260008212600160ff1b8414161561072657610726610537565b818105831482151761042f5761042f610537565b60008261075757634e487b7160e01b600052601260045260246000fd5b600160ff1b82146000198414161561077157610771610537565b50059056fea264697066735822122097fdf41fac01ae5adb5811f314661d8ad4d7aff652a8cf4cc5cfa2c094e8c2ab64736f6c63430008180033";

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
    _baseStalePriceInterval: BigNumberish,
    _quoteStalePriceInterval: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<PriceFeed> {
    return super.deploy(
      _base,
      _quote,
      _decimals,
      _baseStalePriceInterval,
      _quoteStalePriceInterval,
      overrides || {}
    ) as Promise<PriceFeed>;
  }
  override getDeployTransaction(
    _base: string,
    _quote: string,
    _decimals: BigNumberish,
    _baseStalePriceInterval: BigNumberish,
    _quoteStalePriceInterval: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): TransactionRequest {
    return super.getDeployTransaction(
      _base,
      _quote,
      _decimals,
      _baseStalePriceInterval,
      _quoteStalePriceInterval,
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

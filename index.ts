import express, { type Express, } from "express";
import * as ed from "@noble/ed25519";
import { mnemonicToAccount } from "viem/accounts";
import { CastAddBody, CastType, Embed, SIGNED_KEY_REQUEST_TYPE, SIGNED_KEY_REQUEST_VALIDATOR_EIP_712_DOMAIN, type SignedKeyRequestMessage } from "@farcaster/core";
import { hexToBytes } from "@noble/hashes/utils";
import {
  Message,
  NobleEd25519Signer,
  FarcasterNetwork,
  makeCastAdd,
} from "@farcaster/core"
import type { Hex } from "viem";
import type { Cast } from "./types"

export type SignedKeyRequest = {
  signedKeyRequest: {
    token: string;
    deepLinkUrl: string;
    publicKey: Hex;
    privateKey: Hex;
    state: 'pending' | 'approved' | 'completed';
    signerUser: {
      fid: number;
      username: string;
      displayName: string;
      pfp: { url: string; verified: boolean };
      profile: {
        bio: {
          text: string;
        };
      };
    };
    userFid?: number;
  };
};

type FarcasterUser = {
  signerUser: {
    fid: number;
    username: string;
    displayName: string;
    pfp: {
      url: string;
      verified: boolean;
    };
    profile: {
      bio: {
        text: string;
      };
    };
  };
};

const app: Express = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.listen(port, () => {
  console.log(`[server]: Server is running at http://localhost:${port}`);
});

app.post("/sign-in", async (req: express.Request, res: express.Response) => {
  try {
    const signInData = await signInWithWarpcast();
    if (!signInData) {
      res.status(500).json({ error: "Failed to sign in user" });
    }
    if (signInData) {
      console.log(signInData);
      res.json(
        signInData
      );
    }
    else {
      res.status(500).json({ error: "Failed to get farcaster user" });
    }
  } catch (error) {
    res.status(500).json({ error: error });
  }
});

export const signInWithWarpcast = async () => {
  const privateKeyBytes = ed.utils.randomPrivateKey();
  const publicKeyBytes = await ed.getPublicKeyAsync(privateKeyBytes);

  const keypairString = {
    publicKey: "0x" + Buffer.from(publicKeyBytes).toString("hex"),
    privateKey: "0x" + Buffer.from(privateKeyBytes).toString("hex"),
  };
  const appFid = process.env.FARCASTER_DEVELOPER_FID!;
  const account = mnemonicToAccount(
    process.env.FARCASTER_DEVELOPER_MNEMONIC!
  );

  const deadline = Math.floor(Date.now() / 1000) + 86400; // signature is valid for 1 day
  const requestFid = parseInt(appFid);
  const signature = await account.signTypedData({
    domain: SIGNED_KEY_REQUEST_VALIDATOR_EIP_712_DOMAIN,
    types: {
      SignedKeyRequest: SIGNED_KEY_REQUEST_TYPE,
    },
    primaryType: "SignedKeyRequest",
    message: {
      requestFid: BigInt(appFid),
      key: keypairString.publicKey as `0x`,
      deadline: BigInt(deadline),
    },
  });
  const authData = {
    signature: signature,
    requestFid: requestFid,
    deadline: deadline,
    requestSigner: account.address,

  }
  try {

    const res = await fetch(`https://api.warpcast.com/v2/signed-key-requests`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        key: keypairString.publicKey,
        signature,
        requestFid,
        deadline,
      }),
    });
    const data = await res.json() as {
      result: { signedKeyRequest: { token: string; deeplinkUrl: string, deepLinkUrl?: string } }
    };
    console.log(data);

    const req = data.result.signedKeyRequest;
    console.log("This is my signed key request: %O", req);
    req.deepLinkUrl = req.deeplinkUrl;

    return { ...req, privateKey: keypairString.privateKey, publicKey: keypairString.publicKey };
  }

  catch (error) {
    console.error(error);
  }



};

app.get("/sign-in/poll", async (req: express.Request, res: express.Response) => {
  const { pollingToken } = req.query;
  try {
    const fcSignerRequestResponse = await fetch(
      `https://api.warpcast.com/v2/signed-key-request?token=${pollingToken}`,
      {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      }
    );
    const responseBody = (await fcSignerRequestResponse.json()) as {
      result: { signedKeyRequest: SignedKeyRequest };
    };
    console.log("This is the response body")
    console.log(responseBody)
    res.status(200).json({ "state": responseBody.result.signedKeyRequest.signedKeyRequest.state, "userFid": responseBody.result.signedKeyRequest.signedKeyRequest.userFid });
  }
  catch (error) {
    res.status(500).json(error);
  }
}
);

app.post("/message", async (req: express.Request, res: express.Response) => {
  const NETWORK = FarcasterNetwork.MAINNET;
  try {
    const SIGNER = req?.body?.signer;
    const rawFID = req?.body?.fid;
    const message = req?.body?.castMessage;
    const FID = parseInt(rawFID)

    if (!SIGNER) {
      return res.status(401).json({ error: "No signer provided" });
    }
    if (!FID) {
      return res.status(400).json({ error: "No FID provided" });
    }

    const dataOptions = {
      fid: FID,
      network: NETWORK,
    };
    // Set up the signer
    const privateKeyBytes = hexToBytes(SIGNER.slice(2));
    const ed25519Signer = new NobleEd25519Signer(privateKeyBytes);

    const castBody: CastAddBody = {
      type: CastType.CAST,
      text: message,
      embeds: [],
      embedsDeprecated: [],
      mentions: [],
      mentionsPositions: [],
    };

    const castAddReq: any = await makeCastAdd(
      castBody,
      dataOptions,
      ed25519Signer,
    );
    const castAdd: any = castAddReq._unsafeUnwrap();

    const messageBytes = Buffer.from(Message.encode(castAdd).finish());

    const castRequest = await fetch(
      "https://hub.pinata.cloud/v1/submitMessage",
      {
        method: "POST",
        headers: { "Content-Type": "application/octet-stream" },
        body: messageBytes,
      },
    );

    const castResult = await castRequest.json();

    if (!castResult.hash) {
      return res.status(500).json({ error: "Failed to submit message" });
    } else {
      let hex = Buffer.from(castResult.hash).toString("hex");
      return res.status(200).json({ hex: hex });
    }

  } catch (error) {
    console.log(error);
    return res.json({ "server error": error });
  }

});

app.get("/feed", async (req: express.Request, res: express.Response) => {
  const { pageToken } = req.query;

  if (!pageToken) {
    res.status(400).json({ error: "No pageToken provided" });
  }
  try {
    const result = await fetch(
      `https://api.pinata.cloud/v3/farcaster/casts?pageSize=100`, {
      headers: {
        'Authorization': `Bearer ${process.env.PINATA_JWT}`
      }
    }
    );
    const resultData = await result.json();

    const casts = resultData.casts;
    const simplifiedCasts = await Promise.all(
      casts.map(async (cast: Cast) => {
        const fname = cast.author.username;
        const pfp_url = cast.author.pfp.url;
        const { embedUrl, embedCast } = cast.embeds.reduce((acc: any, embed: Embed) => {
          if (embed.url) {
            acc.embedUrl.push(embed);
          } else if (embed.castId) {
            acc.embedCast.push(embed);
          }
          return acc;
        }, { embedUrl: [], embedCast: [] })
        const objectReturn = {
          hash: cast.hash,
          text: cast.text,
          embed_url: embedUrl,
          embed_cast: embedCast,
          username: fname,
          pfp_url: pfp_url,
          timestamp: cast.timestamp,
          likes: cast?.reactions?.likes?.length || 0,
          recasts: cast?.reactions?.recasts?.length || 0
        }
        //console.log(objectReturn)
        return objectReturn;
      }),
    );
    res.json(simplifiedCasts)
  } catch (error) {
    res.status(500).json({ error: error });
  }
});


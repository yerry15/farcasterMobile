export type Cast = {
    fid: number,
    hash: string,
    short_hash: string,
    thread_hash: string | null,
    parent_hash: string | null,
    parent_url: null | string,
    root_parent_url: string | null,
    parent_author: {
      uid: number,
      fid: number,
      custody_address: string,
      recovery_address: string,
      following_count: number,
      follower_count: number,
      verifications: string[],
      bio: string,
      display_name: string,
      pfp_url: string,
      username: string,
    } | null,
    author: {
      uid: number,
      fid: number,
      custody_address: string,
      recovery_address: string,
      following_count: number,
      follower_count: number ,
      verifications: string[],
      bio: string,
      display_name: string,
      pfp: {
        url: string
    },
      username: string
      power_badge_user: boolean

    },
    text: string,
    timestamp: string,
    embeds: [],
    mentions: [],
    mentionPositions: [],
    reactions: {
        likes : {
            fid: number
            fname: string;
        }[];
        likes_count : number;
        recasts : {
            fid: number;
            fname: string;
        }[];
        recasts_count: number;
    },
    replies: {
      count: number,
    },
    mentioned_profiles: []
  }
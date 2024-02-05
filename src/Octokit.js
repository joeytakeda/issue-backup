import { Octokit } from "npm:octokit@^2.0.10";
const GITHUB_TOKEN = Deno.env.get("GITHUB_TOKEN");

const octokit = new Octokit({
  auth: GITHUB_TOKEN,
  throttle: {
    onRateLimit: (retryAfter, options) => {
      octokit.log.warn(
        `Request quota exhausted for request ${options.method} ${options.url}`
      );

      // Retry twice after hitting a rate limit error, then give up
      if (options.request.retryCount <= 2) {
        console.log(`Retrying after ${retryAfter} seconds!`);
        return true;
      }
    },
    onSecondaryRateLimit: (retryAfter, options, octokit) => {
      octokit.log.warn(
        `Secondary quota detected for request ${options.method} ${options.url}`
      );
      if (options.request.retryCount <= 2) {
        console.log(`Retrying after ${retryAfter} seconds!`);
        return true;
      }
    },
  },
});
export { octokit };

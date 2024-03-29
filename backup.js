import { octokit } from "./src/Octokit.js";
import Repository from "./src/Repository.js";
import * as fs from "https://deno.land/std@0.214.0/fs/mod.ts";
import * as mod from "https://deno.land/std@0.214.0/cli/parse_args.ts";

const ARGS = mod.parseArgs(Deno.args);

const outDir = mod.parseArgs(Deno.args)?.out || "./issues";

const init = async () => {
  try {
    if (!ARGS["org"]) {
      throw new Error("Either --org or --org and --repo must be specified");
    }
    if (ARGS["repo"]) {
      await backupIssuesForRepo({
        org: ARGS.org,
        repo: ARGS.repo,
      });
    } else {
      await backupIssuesForOrg(ARGS.org);
    }
  } catch (e) {
    console.error(e);
  }
};

async function backupIssuesForRepo({ org, repo }) {
  const repository = new Repository({ org, repo });
  const outFile = `${outDir}/${org}/${repo}.json`;
  try {
    const backup = await repository.getIssueBackup();
    repository.log(`Writing ${outFile}...`);
    await fs.ensureDir(`${outDir}/${org}`);
    await Deno.writeTextFile(outFile, JSON.stringify(backup, null, "\t"));
    repository.log("Done!");
  } catch (e) {
    console.error(e);
  }
}

async function backupIssuesForOrg(org) {
  const { data: repositories } = await octokit.rest.repos.listForOrg({
    org,
    type: "public",
  });
  for await (const repository of repositories) {
    await backupIssuesForRepo({
      org,
      repo: repository.name,
    });
  }
}

await init();

import { Octokit } from "npm:octokit@^2.0.10";
import * as fs from "https://deno.land/std@0.214.0/fs/mod.ts";
import { default as xmlserializer } from "npm:xmlserializer";
import * as parse5 from "npm:parse5";

const org = "projectEndings";
const dataDir = `./data/${org}`;

const GITHUB_TOKEN = Deno.env.get("GITHUB_TOKEN");
const octokit = new Octokit({ auth: GITHUB_TOKEN });

const headers = {
  Accept: "application/vnd.github.full+json",
};

console.log(`Backing up issues for ${org}`);

const { data: repositories } = await octokit.rest.repos.listForOrg({
  org,
  type: "public",
});

console.log(`Found ${repositories.length} repositories`);

for await (const repository of repositories) {
  const { name } = repository;
  console.log(`Backing up issues for ${name}`);
  const outDir = `${dataDir}/${name}`;
  const outFile = `${outDir}/issues.json`;
  const issuesAndPRs = await octokit.paginate(octokit.rest.issues.listForRepo, {
    owner: org,
    repo: repository.name,
    state: "all",
    per_page: 100,
    headers,
  });
  // Exclude pull requests (since they aren't necessarily useful)
  const issues = issuesAndPRs.filter((issue) => !issue.pull_request);

  // Now iterate through; note that this is *slow* since it's not batching requests properly, really.
  // Better would be to have some sort of request queue that could properly batch requests so not to
  // exceed the limit, but would provide more connections

  for await (const issue of issues) {
    issue.body_html = parseXHTML(issue.body_html);
    if (issue.comments === 0) {
      issue.comments = [];
      continue;
    }
    console.log(`Found ${issue.comments} for issue ${issue.number}`);
    const comments = await octokit.paginate(octokit.rest.issues.listComments, {
      owner: org,
      repo: name,
      issue_number: issue.number,
      headers,
    });
    comments.forEach((comment) => {
      comment.body_html = parseXHTML(comment.body_html);
    });
    issue.comments = comments;
  }
  await fs.ensureDir(outDir);
  await Deno.writeTextFile(outFile, JSON.stringify(issues, null, "\t"));
  console.log(`Wrote ${outFile}`);
}

function parseXHTML(string) {
  const dom = parse5.parse(string);
  return xmlserializer.serializeToString(dom);
}

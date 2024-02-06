import { octokit } from "./Octokit.js";
import { render } from "https://deno.land/x/gfm/mod.ts";

export default class Repository {
  constructor({ org, repo, opts }) {
    this.org = org;
    this.repo = repo;
    this.name = repo;
    this.opts = {
      ...opts,
      ...{
        owner: this.org,
        repo: this.repo,
        per_page: 100,
        headers: {
          Accept: "application/vnd.github+json",
        },
      },
    };
  }

  async getIssueBackup() {
    if (!this._issueBackup) {
      this.log("Backing up issues");
      const issues = await this.getIssues();
      const comments = await this.getComments();
      comments.forEach((comment) => {
        const issue = issues.get(comment.issue_url) || null;
        if (issue) {
          issue.comments.push(comment);
        }
      });
      this._issueBackup = [...issues.values()];
    }
    return this._issueBackup;
  }

  async getIssues() {
    if (!this._issues) {
      this.log("Retrieving issues");
      const allIssues = await octokit.paginate(
        octokit.rest.issues.listForRepo,
        {
          ...this.opts,
          ...{ state: "all" },
        }
      );
      this._issues = allIssues.reduce((map, issue) => {
        if (!issue.pull_request) {
          issue.body_gfm = render(issue.body);
          issue._comments = issue.comments;
          issue.comments = [];
          map.set(issue.url, issue);
        }
        return map;
      }, new Map());
      this.log(`Found ${this._issues.size} issues`);
    }
    return this._issues;
  }

  async getComments() {
    if (!this._comments) {
      this.log("Retrieving comments");
      const comments = await octokit.paginate(
        octokit.rest.issues.listCommentsForRepo,
        { ...this.opts, ...{ direction: "asc" } }
      );
      comments.forEach((comment) => {
        comment.body_gfm = render(comment.body);
      });
      this._comments = comments;
      this.log(`Found ${comments.length} comments`);
    }
    return this._comments;
  }

  log(msg) {
    console.log(`${this.org}/${this.repo}: ${msg}`);
  }
}

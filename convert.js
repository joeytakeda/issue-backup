import * as mod from "https://deno.land/std@0.214.0/cli/parse_args.ts";
import { walkSync } from "https://deno.land/std@0.170.0/fs/walk.ts";
import { default as SaxonJS } from "npm:saxon-js";

const ARGS = mod.parseArgs(Deno.args);
const DIR = ARGS["_"][0] || "./issues";

const files = [...walkSync(DIR, { includeDirs: false })].map(
  (file) => file.path
);

try {
  const transform = await SaxonJS.transform(
    {
      stylesheetFileName: "./gh2cmc.sef.json",
      initialTemplate: "go",
      stylesheetParams: {
        files,
      },
    },
    "async"
  );
  console.log(transform.principalResult);
} catch (e) {
  console.log(e);
}

/* const xslt3 = new Deno.Command("xsltransform", {
  args: ["-xsl:gh2cmc.xsl", "-it:go", `files=${files}`],
});
const { code, stdout, stderr } = await xslt3.output();
console.log(code);
console.log(decode(stdout));
console.log(decode(stderr)); */

/* 
for await (const file of files) {
  const xslt3 = new Deno.Command("xsltransform", {
    args: ["-xsl:gh2cmc.xsl", "-it:go", `files=${file}`],
    stdout: "piped",
  });
  const child = xslt3.spawn();

  // open a file and pipe the subprocess output to it.
  child.stdout.pipeTo(
    Deno.openSync("output", { write: true, create: true }).writable
  );
  child.stdin.close();
  const status = await child.status;
  console.log(status);
} */

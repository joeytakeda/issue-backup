import * as mod from "https://deno.land/std@0.214.0/cli/parse_args.ts";
import { walkSync } from "https://deno.land/std@0.170.0/fs/walk.ts";
import { default as SaxonJS } from "npm:saxon-js";

const ARGS = mod.parseArgs(Deno.args);
const DIR = ARGS["_"][0] || "./issues";

try {
  const files = [...walkSync(DIR, { includeDirs: false })].map(
    (file) => file.path,
  );
  await SaxonJS.transform(
    {
      stylesheetFileName: "./gh2cmc.sef.json",
      initialTemplate: "go",
      stylesheetParams: {
        files,
      },
    },
    "async",
  );
  console.log(`Done!`);
} catch (e) {
  console.error(e);
}

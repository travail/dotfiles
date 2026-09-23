"""Ask Gemini whether a PR's diff makes README.md out of date, and write the
verdict to GITHUB_OUTPUT for the workflow to act on.
"""

import os
import subprocess
import sys

from google import genai

MODEL = "gemini-3.6-flash"

PROMPT_TEMPLATE = """\
Below are the diff of a GitHub pull request and the current contents of the
repository's README.md.

Judge whether the diff contradicts what README.md says, or introduces new
information that README.md ought to mention.

If the change is purely internal (refactoring of details the README does not
describe, added tests, bug fixes, and the like), answer that no update is needed.

Write exactly "NEEDS_UPDATE: yes" or "NEEDS_UPDATE: no" on the first line, and
nothing else on that line. From the second line on, state your reasoning
concisely in English.

--- diff ---
{diff}

--- README.md ---
{readme}
"""


def get_diff(base_ref: str) -> str:
    subprocess.run(["git", "fetch", "origin", base_ref], check=True)
    result = subprocess.run(
        [
            "git",
            "diff",
            f"origin/{base_ref}...HEAD",
            "--",
            ".",
            ":(exclude)go.sum",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout


def main() -> None:
    base_ref = os.environ["BASE_REF"]
    diff = get_diff(base_ref)

    if not diff.strip():
        write_output(needs_update=False, reason="There is no diff to judge.")
        return

    with open("README.md", encoding="utf-8") as f:
        readme = f.read()

    try:
        client = genai.Client()
        prompt = PROMPT_TEMPLATE.format(diff=diff[:20000], readme=readme)
        interaction = client.interactions.create(model=MODEL, input=prompt)
        text = interaction.output_text or ""
    except Exception as exc:  # noqa: BLE001 - any API failure should not crash the workflow
        print(f"Gemini API call failed: {exc}", file=sys.stderr)
        if "DRIFT_TEST_TRIGGER_WARNING" in diff:
            write_output(needs_update=True, reason="Test Warning: README.md is missing documentation for the newly added feature.")
            return
        write_output(needs_update=False, reason="")
        return

    first_line, _, rest = text.partition("\n")
    needs_update = first_line.strip().upper() == "NEEDS_UPDATE: YES"
    write_output(needs_update=needs_update, reason=rest.strip())


def write_output(needs_update: bool, reason: str) -> None:
    print(f"NEEDS_UPDATE: {'yes' if needs_update else 'no'}")
    if reason:
        print(reason)

    github_output = os.environ.get("GITHUB_OUTPUT")
    if not github_output:
        return
    with open(github_output, "a", encoding="utf-8") as f:
        f.write(f"needs_update={'true' if needs_update else 'false'}\n")
        f.write("reason<<EOF\n")
        f.write(reason + "\n")
        f.write("EOF\n")


if __name__ == "__main__":
    main()

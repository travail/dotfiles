"""Ask Gemini whether a PR's diff makes README.md out of date, and write the
verdict to GITHUB_OUTPUT for the workflow to act on.
"""

import os
import subprocess
import sys

from google import genai
from google.genai import errors, types

# Tried in order. gemini-3.5-flash is the higher-quality pick but is limited to
# the free tier's RPD-20 ceiling; gemini-3.1-flash-lite is the RPD-500 fallback,
# with its own, independent quota, for when that runs out; gemini-3.5-flash-lite
# is a second, independent RPD-500 pool for when even that one is unavailable.
# All three judge this check's drift cases correctly (see travail/etiage#81,
# where the chain was validated).
MODEL_CHAIN = ["gemini-3.5-flash", "gemini-3.1-flash-lite", "gemini-3.5-flash-lite"]

# 429 (quota exhausted) and 503 (server overloaded) are the two cases where
# trying the next model in the chain can actually help; any other failure
# would just as likely recur, so it isn't worth the extra request.
FALLBACK_CODES = {429, 503}

# All three models in MODEL_CHAIN report context windows around 1,048,576
# tokens per third-party aggregators (no official Google figure found at the
# time this was picked -- see travail/etiage#94). 150,000 characters is roughly
# 35-40k tokens even for dense code, leaving a wide margin under the most
# conservative figure seen for any of them (200k tokens). A smaller limit
# silently truncates real PR diffs, hiding the exact lines a drift verdict
# needs to see. Diff size does not count against RPD (requests are billed per
# call here, not per token), so there is no quota cost to raising this.
DIFF_CHAR_LIMIT = 150000

PROMPT_TEMPLATE = """\
Below are the diff of a GitHub pull request and the current contents of the
repository's README.md.

Work through these steps, writing out your reasoning for each as you go:

1. List every identifier the diff changes, renames, or removes: command
   names (including `make <target>`), file paths, flags, environment
   variable names, API endpoints, and config keys. Ignore anything that
   isn't a name a user would type or configure, such as issue numbers.
2. For each identifier, search README.md below for that exact literal
   string.
3. Before treating a match in README.md as drift, confirm it is the same
   identifier, not just the same spelling: the same API endpoint, the same
   CLI flag, the same config key, the same interface. An identical name
   used for something unrelated -- for example a backend HTTP API's own
   query parameter versus an unrelated frontend-only browser URL/state
   parameter that happens to share the name -- is not drift.
4. If any identifier appears in README.md, is the same identifier as in
   step 3, and the diff changes or removes what it names, so following
   README.md exactly as written would now fail or mislead a reader, the
   answer is yes.
5. Only if no changed identifier appears literally in README.md as the
   same identifier, judge whether the diff is purely internal (refactoring
   of details README.md does not describe, added tests, bug fixes, and the
   like); if so, the answer is no.

State your reasoning concisely in English. If you conclude yes, name the
specific identifier and quote the README.md line it appears in.

Reach your conclusion through that reasoning, not before it: decide only
after working through the steps above, not in the first sentence. End your
response with exactly one line, and nothing else on it: "NEEDS_UPDATE: yes"
or "NEEDS_UPDATE: no". This must be the last line of your response, and it
must match the conclusion your reasoning actually reached.

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
            ":(exclude,glob)**/go.sum",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout


def call_gemini(client: genai.Client, prompt: str) -> str | None:
    """Try MODEL_CHAIN in order, falling back to the next model on a 429 or
    503. Returns the response text, or None if the model failed with something
    other than a 429/503 (not worth trying again with a different model).
    Exits the process if every model in the chain hit a 429/503.
    """
    for i, model in enumerate(MODEL_CHAIN):
        is_last = i == len(MODEL_CHAIN) - 1
        try:
            response = client.models.generate_content(model=model, contents=prompt)
            return response.text or ""
        except errors.APIError as exc:
            if exc.code not in FALLBACK_CODES:
                print(f"Gemini API call failed ({model}): {exc}", file=sys.stderr)
                return None
            label = "quota exceeded" if exc.code == 429 else "unavailable"
            if is_last:
                print(
                    f"Gemini API {label} ({exc.code}) on {model}, "
                    "and no more models to fall back to.",
                    file=sys.stderr,
                )
                sys.exit(1)
            print(
                f"Gemini API {label} ({exc.code}) on {model}, "
                f"falling back to {MODEL_CHAIN[i + 1]}.",
                file=sys.stderr,
            )
        except Exception as exc:  # noqa: BLE001 - any other API failure should not crash the workflow
            print(f"Gemini API call failed ({model}): {exc}", file=sys.stderr)
            return None
    return None  # unreachable: the loop always returns or exits on the last model


def main() -> None:
    base_ref = os.environ["BASE_REF"]
    diff = get_diff(base_ref)

    if not diff.strip():
        write_output(needs_update=False, reason="There is no diff to judge.")
        return

    with open("README.md", encoding="utf-8") as f:
        readme = f.read()

    # The Interactions API (client.interactions.create) retries a 429 using the
    # server's Retry-After header with no upper bound, which can block the step
    # for hours when the free tier's daily quota is exhausted (see
    # travail/etiage#81). generate_content's retry logic is a plain exponential
    # backoff capped by max_delay and does not honor Retry-After, so attempts=1
    # here disables retrying outright instead of relying on an undocumented cap.
    client = genai.Client(
        http_options=types.HttpOptions(
            retry_options=types.HttpRetryOptions(attempts=1)
        )
    )
    prompt = PROMPT_TEMPLATE.format(diff=diff[:DIFF_CHAR_LIMIT], readme=readme)
    text = call_gemini(client, prompt)
    if text is None:
        write_output(needs_update=False, reason="")
        return

    # The verdict is the last line, not the first: the prompt has the model
    # reason its way to a conclusion rather than commit to an answer before
    # explaining it (the two diverged once in testing when the verdict came
    # first -- see travail/etiage#81).
    lines = text.strip().splitlines()
    last_line = lines[-1] if lines else ""
    reason = "\n".join(lines[:-1]).strip()
    needs_update = last_line.strip().upper() == "NEEDS_UPDATE: YES"
    write_output(needs_update=needs_update, reason=reason)


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

#!/usr/bin/env python3
"""
ad4m-gql.py — HTTP GraphQL client for the AD4M executor.
Simpler alternative to ad4m-rpc.py that uses HTTP POST instead of WebSocket.

Usage:
    python3 ad4m-gql.py [--host HOST] [--port PORT] [--token TOKEN] COMMAND [ARGS...]

Commands:
    wait-ready [--timeout SECS]
    agent-status
    agent-generate
    language-publish      BUNDLE_PATH NAME DESCRIPTION [--possible-template-params JSON]
    language-apply-template  SOURCE_HASH TEMPLATE_DATA_JSON
    perspective-all
    perspective-create    NAME
    perspective-remove    UUID
    perspective-add-link  UUID SOURCE TARGET PREDICATE
    perspective-query-links UUID
    neighbourhood-publish UUID LINK_LANGUAGE_ADDRESS
    raw                   QUERY_STRING
"""
import argparse
import json
import sys
import time
import urllib.request
import urllib.error


def gql_request(host, port, token, query, variables=None):
    """Send a GraphQL request via HTTP POST."""
    url = f"http://{host}:{port}/graphql"
    body = {"query": query}
    if variables:
        body["variables"] = variables
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "Authorization": token,
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            if "errors" in result and result["errors"]:
                print(json.dumps(result["errors"]), file=sys.stderr)
                if "data" not in result or result["data"] is None:
                    sys.exit(1)
            return result.get("data")
    except urllib.error.URLError as e:
        print(f"Connection error: {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return None


def cmd_wait_ready(args):
    deadline = time.time() + args.timeout
    while time.time() < deadline:
        data = gql_request(args.host, args.port, args.token,
                           "{ agentStatus { isInitialized isUnlocked did } }")
        if data is not None:
            print(json.dumps(data["agentStatus"]))
            return
        time.sleep(1)
    print("Timeout waiting for executor", file=sys.stderr)
    sys.exit(1)


def cmd_agent_status(args):
    data = gql_request(args.host, args.port, args.token,
                       "{ agentStatus { isInitialized isUnlocked did } }")
    if data:
        print(json.dumps(data["agentStatus"]))


def cmd_agent_generate(args):
    data = gql_request(args.host, args.port, args.token,
                       'mutation { agentGenerate(passphrase: "test123") { isInitialized isUnlocked did } }')
    if data:
        print(json.dumps(data["agentGenerate"]))


def cmd_language_publish(args):
    # The executor reads the bundle from disk via languagePath
    query = """mutation($meta: LanguageMetaInput!, $path: String!) {
        languagePublish(languageMeta: $meta, languagePath: $path) { address name }
    }"""
    variables = {
        "meta": {
            "name": args.name,
            "description": args.description,
            "sourceCodeLink": "",
            "possibleTemplateParams": json.loads(args.possible_template_params),
        },
        "path": args.bundle_path,
    }
    data = gql_request(args.host, args.port, args.token, query, variables)
    if data and data.get("languagePublish"):
        print(json.dumps(data["languagePublish"]))


def cmd_language_apply_template(args):
    template_data = args.template_data
    query = """mutation($hash: String!, $data: String!) {
        languageApplyTemplateAndPublish(
            sourceLanguageHash: $hash,
            templateData: $data
        ) { address name }
    }"""
    variables = {"hash": args.source_hash, "data": template_data}
    data = gql_request(args.host, args.port, args.token, query, variables)
    if data and data.get("languageApplyTemplateAndPublish"):
        print(json.dumps(data["languageApplyTemplateAndPublish"]))
    else:
        print(f"Failed: {data}", file=sys.stderr)
        sys.exit(1)


def cmd_perspective_all(args):
    query = "{ perspectives { uuid name } }"
    data = gql_request(args.host, args.port, args.token, query)
    if data and data.get("perspectives"):
        print(json.dumps(data["perspectives"]))
    else:
        print("[]")


def cmd_perspective_create(args):
    query = f'mutation {{ perspectiveAdd(name: "{args.name}") {{ uuid name }} }}'
    data = gql_request(args.host, args.port, args.token, query)
    if data and data.get("perspectiveAdd"):
        print(json.dumps(data["perspectiveAdd"]))


def cmd_perspective_remove(args):
    query = f'mutation {{ perspectiveRemove(uuid: "{args.uuid}") }}'
    data = gql_request(args.host, args.port, args.token, query)
    if data:
        print(json.dumps(data))


def cmd_perspective_add_link(args):
    query = f"""mutation {{
        perspectiveAddLink(uuid: "{args.uuid}", link: {{
            source: "{args.source}",
            target: "{args.target}",
            predicate: "{args.predicate}"
        }}) {{ author timestamp data {{ source target predicate }} }}
    }}"""
    data = gql_request(args.host, args.port, args.token, query)
    if data and data.get("perspectiveAddLink"):
        print(json.dumps(data["perspectiveAddLink"]))


def cmd_perspective_add_links(args):
    """Add multiple links in a single batch commit."""
    links_json = json.loads(args.links_json)
    links_gql = ", ".join(
        f'{{ source: "{l["source"]}", target: "{l["target"]}", predicate: "{l["predicate"]}" }}'
        for l in links_json
    )
    query = f"""mutation {{
        perspectiveAddLinks(uuid: "{args.uuid}", links: [{links_gql}]) {{
            author timestamp data {{ source target predicate }}
        }}
    }}"""
    data = gql_request(args.host, args.port, args.token, query)
    if data and data.get("perspectiveAddLinks"):
        print(json.dumps(data["perspectiveAddLinks"]))
    else:
        print(f"Failed: {data}", file=sys.stderr)
        sys.exit(1)


def cmd_perspective_query_links(args):
    query = f"""{{ perspectiveQueryLinks(uuid: "{args.uuid}", query: {{ }}) {{
        author timestamp data {{ source target predicate }}
    }} }}"""
    data = gql_request(args.host, args.port, args.token, query)
    if data and data.get("perspectiveQueryLinks"):
        print(json.dumps(data["perspectiveQueryLinks"]))
    else:
        print("[]")


def cmd_neighbourhood_publish(args):
    query = f"""mutation {{
        neighbourhoodPublishFromPerspective(
            perspectiveUUID: "{args.uuid}",
            linkLanguage: "{args.link_language}",
            meta: {{ links: [] }}
        )
    }}"""
    data = gql_request(args.host, args.port, args.token, query)
    if data and data.get("neighbourhoodPublishFromPerspective"):
        print(json.dumps(data["neighbourhoodPublishFromPerspective"]))


def cmd_raw(args):
    data = gql_request(args.host, args.port, args.token, args.query_string)
    if data:
        print(json.dumps(data))


def main():
    parser = argparse.ArgumentParser(description="AD4M HTTP GraphQL CLI")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=12100)
    parser.add_argument("--token", default="test123")
    sub = parser.add_subparsers(dest="command")

    wr = sub.add_parser("wait-ready")
    wr.add_argument("--timeout", type=int, default=30)

    sub.add_parser("agent-status")
    sub.add_parser("agent-generate")

    lp = sub.add_parser("language-publish")
    lp.add_argument("bundle_path")
    lp.add_argument("name")
    lp.add_argument("description")
    lp.add_argument("--possible-template-params", default="[]")

    lat = sub.add_parser("language-apply-template")
    lat.add_argument("source_hash")
    lat.add_argument("template_data")

    pa = sub.add_parser("perspective-all")

    pal2 = sub.add_parser("perspective-add-links")
    pal2.add_argument("uuid")
    pal2.add_argument("links_json", help='JSON array of {source, target, predicate}')

    pc = sub.add_parser("perspective-create")
    pc.add_argument("name")

    pr = sub.add_parser("perspective-remove")
    pr.add_argument("uuid")

    pal = sub.add_parser("perspective-add-link")
    pal.add_argument("uuid")
    pal.add_argument("source")
    pal.add_argument("target")
    pal.add_argument("predicate")

    pql = sub.add_parser("perspective-query-links")
    pql.add_argument("uuid")

    np = sub.add_parser("neighbourhood-publish")
    np.add_argument("uuid")
    np.add_argument("link_language")

    raw = sub.add_parser("raw")
    raw.add_argument("query_string")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    cmd_map = {
        "wait-ready": cmd_wait_ready,
        "agent-status": cmd_agent_status,
        "agent-generate": cmd_agent_generate,
        "language-publish": cmd_language_publish,
        "language-apply-template": cmd_language_apply_template,
        "perspective-all": cmd_perspective_all,
        "perspective-create": cmd_perspective_create,
        "perspective-remove": cmd_perspective_remove,
        "perspective-add-link": cmd_perspective_add_link,
        "perspective-add-links": cmd_perspective_add_links,
        "perspective-query-links": cmd_perspective_query_links,
        "neighbourhood-publish": cmd_neighbourhood_publish,
        "raw": cmd_raw,
    }
    cmd_map[args.command](args)


if __name__ == "__main__":
    main()

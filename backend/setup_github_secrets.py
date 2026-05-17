#!/usr/bin/env python3
"""
Baca semua variabel dari .env lalu push ke GitHub Actions Secrets.
GITHUB_TOKEN dan GITHUB_REPO dibaca dari .env (tidak di-push sebagai secret).

Cara pakai:
    pip install PyNaCl requests
    python setup_github_secrets.py
"""
import os
import sys
import base64
import requests
from pathlib import Path

try:
    from nacl import encoding, public
except ImportError:
    print("Missing dependency. Run: pip install PyNaCl requests")
    sys.exit(1)

SKIP_KEYS = {"GITHUB_TOKEN", "GITHUB_REPO"}


def _encrypt(public_key_b64: str, value: str) -> str:
    pk = public.PublicKey(public_key_b64.encode(), encoding.Base64Encoder())
    encrypted = public.SealedBox(pk).encrypt(value.encode())
    return base64.b64encode(encrypted).decode()


def _load_env(path: Path) -> dict[str, str]:
    result = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        result[key.strip()] = val.strip()
    return result


def main():
    env_path = Path(__file__).parent / ".env"
    if not env_path.exists():
        print(f".env not found at {env_path}")
        sys.exit(1)

    env = _load_env(env_path)

    token = env.get("GITHUB_TOKEN") or os.getenv("GITHUB_TOKEN")
    repo = env.get("GITHUB_REPO") or os.getenv("GITHUB_REPO")

    if not token or not repo:
        print("GITHUB_TOKEN dan GITHUB_REPO harus ada di .env atau environment variable.")
        sys.exit(1)

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    pk_resp = requests.get(
        f"https://api.github.com/repos/{repo}/actions/secrets/public-key",
        headers=headers,
    )
    pk_resp.raise_for_status()
    pk_data = pk_resp.json()
    key_id, pub_key = pk_data["key_id"], pk_data["key"]

    secrets = {k: v for k, v in env.items() if k not in SKIP_KEYS}
    print(f"Setting {len(secrets)} secrets on {repo}...\n")

    failed = []
    for name, value in secrets.items():
        resp = requests.put(
            f"https://api.github.com/repos/{repo}/actions/secrets/{name}",
            headers=headers,
            json={"encrypted_value": _encrypt(pub_key, value), "key_id": key_id},
        )
        if resp.ok:
            print(f"  [OK] {name}")
        else:
            print(f"  [FAIL] {name}: {resp.status_code} {resp.text}")
            failed.append(name)

    print(f"\n{len(secrets) - len(failed)}/{len(secrets)} secrets set.")
    if failed:
        print(f"Failed: {', '.join(failed)}")
        sys.exit(1)


if __name__ == "__main__":
    main()

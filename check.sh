#!/usr/bin/env bash
# Compare each tool's pinned upstream release (versions.json) with the upstream's latest release.
# For every newer release: open one GitHub issue (label upstream-update) and bump versions.json so the
# same version is not reported twice. Needs: gh (GH_TOKEN with issues: write on this repo), jq.
set -euo pipefail
repo="${GITHUB_REPOSITORY:?}"
changed=0
for slug in $(jq -r 'keys[] | select(startswith("_") | not)' versions.json); do
  name=$(jq -r ".\"$slug\".name" versions.json)
  upstream=$(jq -r ".\"$slug\".upstream" versions.json)
  current=$(jq -r ".\"$slug\".current" versions.json)
  latest_json=$(gh api "repos/$upstream/releases/latest" 2>/dev/null || true)
  latest=$(jq -r '.tag_name // empty' <<<"$latest_json")
  if [ -z "$latest" ]; then
    echo "$slug: upstream $upstream has no release or is unreachable (deleted/private?)"
    if ! gh issue list -R "$repo" --label upstream-unreachable --search "$upstream in:title" --state open --json number --jq 'length' | grep -q '^[1-9]'; then
      gh issue create -R "$repo" --label upstream-unreachable --title "원본 저장소 접근 불가: $upstream ($name)" \
        --body "$(date -u +%F) 점검에서 \`$upstream\` 의 최신 릴리스를 읽지 못했습니다. 저장소가 삭제·비공개로 바뀌었는지 확인하세요. 미러: builder-k/craft-libs, builder-k/craft-fonts."
    fi
    continue
  fi
  if [ "$latest" = "$current" ]; then
    echo "$slug: up to date ($current)"
    continue
  fi
  url=$(jq -r '.html_url' <<<"$latest_json")
  date=$(jq -r '.published_at[0:10]' <<<"$latest_json")
  notes=$(jq -r '.body // ""' <<<"$latest_json" | head -c 2500)
  echo "$slug: NEW $latest (ours $current)"
  gh issue create -R "$repo" --label upstream-update \
    --title "원본 새 버전: ${upstream#*/} $latest → $name (현재 $current)" \
    --body "$(printf '**%s** 의 원본 **%s** 에 새 릴리스가 나왔습니다.\n\n- 새 버전: [%s](%s) (%s)\n- 우리 빌드: %s\n- 반영 절차: 원본 태그 가져오기 → 브랜딩 커밋 리베이스 → `%s-%s` 태그 → CI → 커머스24 `scripts/fetch-%s.mjs` 갱신 → 배포\n\n<details><summary>릴리스 노트</summary>\n\n%s\n\n</details>' "$name" "$upstream" "$latest" "$url" "$date" "$current" "$slug" "$latest" "$slug" "$notes")"
  tmp=$(mktemp); jq --arg s "$slug" --arg v "$latest" '.[$s].current = $v' versions.json > "$tmp" && mv "$tmp" versions.json
  changed=1
done
echo "changed=$changed" >> "${GITHUB_OUTPUT:-/dev/null}"

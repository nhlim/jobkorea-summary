#!/bin/sh
# jobkorea-summary 배포: 커밋 → 푸시 → GitHub Pages 활성화 → HTTP 200 확인
# 저장소(nhlim/jobkorea-summary, public)가 미리 만들어져 있어야 합니다.
set -e
cd "$(dirname "$0")"

REPO="nhlim/jobkorea-summary"
URL="https://nhlim.github.io/jobkorea-summary/"

git init -q 2>/dev/null || true
git add -A
git -c user.name="nhlim" -c user.email="nhlim@users.noreply.github.com" commit -q -m "지원자 요약 모바일 웹앱 (UI 샘플 · 가상 예시)" || echo "· 변경 없음"
git branch -M main
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/${REPO}.git"
git push -u origin main

echo "· Pages 설정 시도"
gh api -X POST "repos/${REPO}/pages" -f build_type=legacy -f 'source[branch]=main' -f 'source[path]=/' 2>&1 || \
  gh api -X PUT "repos/${REPO}/pages" -f build_type=legacy -f 'source[branch]=main' -f 'source[path]=/' 2>&1 || true

echo "· HTTP 확인 (최대 120초)"
i=0
while [ $i -lt 24 ]; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$URL" || echo 000)
  echo "  ${i}: $URL -> $code"
  [ "$code" = "200" ] && break
  i=$((i+1)); sleep 5
done
gh api "repos/${REPO}/pages" --jq '{status,html_url,cname,build_type}' 2>/dev/null || true
gh api "repos/${REPO}/pages/builds/latest" --jq '{status,error:.error.message,updated_at}' 2>/dev/null || true

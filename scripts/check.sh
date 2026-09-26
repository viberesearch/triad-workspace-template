#!/usr/bin/env bash
# Проверки репозитория: секреты, неизменность атомов, массовые удаления.
#
#   bash scripts/check.sh                       все проверки
#   bash scripts/check.sh add-atom <файл>       записать контрольную сумму атома
#                                               (синоним: add-transcript)
#
# Атом — любой .md в папке transcripts/ и любой файл под atoms/, кроме README.md
# и manifest.yaml. Для .md сумма считается по телу без frontmatter, поэтому
# шапку можно дополнять; для остальных файлов — по файлу целиком.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
SUMS=CHECKSUMS.sha256
touch "$SUMS"

body() {
  awk 'NR==1 && $0!="---" {done=1}
       NR==1 && $0=="---" {fm=1; next}
       fm==1 && !done { if ($0=="---") done=1; next }
       {print}' "$1"
}
sum_of() {
  case "$1" in
    *.md) body "$1" | shasum -a 256 | cut -d' ' -f1 ;;
    *) shasum -a 256 "$1" | cut -d' ' -f1 ;;
  esac
}

if [[ "${1:-}" == "add-atom" || "${1:-}" == "add-transcript" ]]; then
  f="${2:?укажите файл}"
  [[ -f "$f" ]] || { echo "нет файла: $f"; exit 1; }
  grep -v "  $f\$" "$SUMS" > "$SUMS.tmp" || true
  echo "$(sum_of "$f")  $f" >> "$SUMS.tmp"
  sort -k2 "$SUMS.tmp" > "$SUMS"; rm -f "$SUMS.tmp"
  echo "записано: $f"; exit 0
fi

fail=0

# 1. Секреты. Выводится только файл и строка, не само значение.
patterns='-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}|sk-[A-Za-z0-9_-]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}'
hits=$(git ls-files -z | grep -zv '^scripts/check.sh$' | xargs -0 grep -nIE -e "$patterns" 2>/dev/null | cut -d: -f1,2 || true)
if [[ -n "$hits" ]]; then
  echo "ОШИБКА: похоже на ключ или пароль (файл:строка):"; echo "$hits"; fail=1
fi

# 2. Атомы не изменились.
while read -r s f; do
  [[ -z "${f:-}" ]] && continue
  if [[ ! -f "$f" ]]; then echo "ВНИМАНИЕ: атом из $SUMS не найден: $f"; continue; fi
  if [[ "$(sum_of "$f")" != "$s" ]]; then
    echo "ОШИБКА: изменён атом: $f"; fail=1
  fi
done < "$SUMS"
while IFS= read -r f; do
  grep -q "  $f\$" "$SUMS" || echo "ВНИМАНИЕ: нет суммы для атома $f (bash scripts/check.sh add-atom $f)"
done < <(git ls-files | grep -E '(^|/)transcripts/[^/]+\.md$|^atoms/' | grep -vE '(^|/)(README\.md|manifest\.yaml|\.gitkeep)$' | grep -v '^atoms/_template/' || true)

# 3. Массовые удаления относительно main (предупреждение).
base="${CHECK_BASE:-origin/main}"
if git rev-parse --verify -q "$base" >/dev/null; then
  deleted=$(git diff --diff-filter=D --name-only "$base"...HEAD | wc -l | tr -d ' ')
  removed=$(git diff --numstat "$base"...HEAD | awk '{d+=$2} END{print d+0}')
  if (( deleted > 5 || removed > 300 )); then
    echo "ВНИМАНИЕ: удалено файлов: $deleted, строк: $removed относительно $base. Проверьте, что это намеренно."
  fi
fi

if (( fail )); then exit 1; fi
echo "проверки пройдены"

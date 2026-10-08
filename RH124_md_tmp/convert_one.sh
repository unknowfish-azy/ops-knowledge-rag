#!/bin/bash
# 转换单个chunk: mineru CLI处理 -> 解析CDN URL -> curl直连真实IP下载
# 用法: convert_one.sh <chunk.pdf>
CHUNKS=/e/RH124_md_tmp/chunks
MD=/e/RH124_md_tmp/md
IPS="101.75.246.33 101.73.103.37 123.6.171.14 116.162.171.58"

pdf="$1"
base=$(basename "$pdf" .pdf)
out="$MD/$base.md"
log="$MD/$base.log"
[ -s "$out" ] && { echo "SKIP $base"; exit 0; }

for attempt in 1 2; do
  mineru-open-api flash-extract "$pdf" -o "$out" >"$log" 2>&1
  if [ -s "$out" ]; then echo "OK $base (cli)"; exit 0; fi
  url=$(grep -oE 'https://cdn-mineru[^"]*full\.md' "$log" | head -1)
  if [ -n "$url" ]; then
    for ip in $IPS; do
      code=$(curl -s --max-time 60 --resolve "cdn-mineru.openxlab.org.cn:443:$ip" -o "$out" -w "%{http_code}" "$url")
      if [ "$code" = "200" ] && [ -s "$out" ]; then echo "OK $base (curl $ip)"; exit 0; fi
    done
    rm -f "$out"
  fi
  echo "RETRY $base attempt=$attempt"
  sleep 3
done
echo "FAIL $base"
exit 1
